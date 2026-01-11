#!/bin/bash
#
# Main build script for DeepX DX-M1 on iMDT V2H SBC
# Run this on your host PC with Docker installed
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
RELEASE_DIR="$SCRIPT_DIR/release"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    log_info "Docker found: $(docker --version)"
}

build_docker_images() {
    log_info "Building Docker images..."
    
    docker build -t deepx-drivers-build -f docker/Dockerfile.drivers docker/
    docker build -t deepx-runtime-build -f docker/Dockerfile.runtime docker/
    
    log_info "Docker images built successfully"
}

clone_sources() {
    log_info "Cloning source repositories..."
    
    mkdir -p "$BUILD_DIR"
    
    # Clone kernel source for driver compilation
    if [ ! -d "$BUILD_DIR/kernel-src" ]; then
        log_info "Cloning Renesas kernel source..."
        git clone --depth 1 https://github.com/imd-tec/renesas-rz-linux-cip.git "$BUILD_DIR/kernel-src"
    fi
    
    # Clone DeepX driver
    if [ ! -d "$BUILD_DIR/dx_rt_npu_linux_driver" ]; then
        log_info "Cloning DeepX driver..."
        git clone --recurse-submodules https://github.com/DEEPX-AI/dx_rt_npu_linux_driver.git "$BUILD_DIR/dx_rt_npu_linux_driver"
    fi
    
    # Clone DeepX SDK
    if [ ! -d "$BUILD_DIR/dx-all-suite" ]; then
        log_info "Cloning DeepX SDK..."
        git clone --recurse-submodules https://github.com/DEEPX-AI/dx-all-suite.git "$BUILD_DIR/dx-all-suite"
    fi
    
    log_info "Source repositories cloned"
}

build_drivers() {
    log_info "Building DeepX drivers..."
    
    docker run --rm -v "$BUILD_DIR:/build" deepx-drivers-build bash -c "
        set -e
        cd /build/kernel-src
        
        # Remove .git to avoid version detection issues
        rm -rf .git
        
        # Create kernel release file
        mkdir -p include/config
        echo '5.10.145-cip17-yocto-standard' > include/config/kernel.release
        
        # Prepare kernel
        make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
        make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules_prepare
        
        # Build DeepX drivers
        cd /build/dx_rt_npu_linux_driver
        make DEVICE=m1 PCIE=deepx ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KERNEL_DIR=/build/kernel-src
        
        # Package drivers
        mkdir -p /build/output/drivers
        cp modules/dxrt_driver.ko /build/output/drivers/
        cp modules/dx_dma.ko /build/output/drivers/
        cp utils/dx_dma/dx_dma.conf /build/output/drivers/
    "
    
    log_info "Drivers built successfully"
}

build_runtime() {
    log_info "Building DeepX runtime..."
    
    # Disable ORT to avoid dependency issues
    sed -i 's/option(USE_ORT "Use ONNX Runtime" ON)/option(USE_ORT "Use ONNX Runtime" OFF)/' \
        "$BUILD_DIR/dx-all-suite/dx-runtime/dx_rt/cmake/dxrt.cfg.cmake" 2>/dev/null || true
    
    docker run --rm -v "$BUILD_DIR:/build" deepx-runtime-build bash -c "
        set -e
        cd /build/dx-all-suite/dx-runtime/dx_rt
        
        # Fix line endings
        find . -type f \( -name '*.sh' -o -name '*.cmake' -o -name 'CMakeLists.txt' \) -exec sed -i 's/\r$//' {} \;
        
        # Build for ARM64
        rm -rf build_aarch64
        ./build.sh --arch aarch64 --type Release || true
        
        # Package runtime
        mkdir -p /build/output/runtime
        cp -r build_aarch64/bin /build/output/runtime/
        cp -r build_aarch64/lib /build/output/runtime/
    "
    
    log_info "Runtime built successfully"
}

create_release() {
    log_info "Creating release package..."
    
    mkdir -p "$RELEASE_DIR"
    
    # Copy drivers
    cp -r "$BUILD_DIR/output/drivers" "$RELEASE_DIR/"
    
    # Copy runtime
    cp -r "$BUILD_DIR/output/runtime" "$RELEASE_DIR/"
    
    # Copy install script
    cp "$SCRIPT_DIR/board/install.sh" "$RELEASE_DIR/"
    chmod +x "$RELEASE_DIR/install.sh"
    
    # Create tarball
    cd "$RELEASE_DIR/.."
    tar czf deepx-release.tar.gz -C "$RELEASE_DIR" .
    mv deepx-release.tar.gz "$SCRIPT_DIR/"
    
    log_info "Release package created: deepx-release.tar.gz"
}

main() {
    log_info "=== DeepX DX-M1 Build Script for iMDT V2H SBC ==="
    
    check_docker
    build_docker_images
    clone_sources
    build_drivers
    build_runtime
    create_release
    
    log_info "=== Build completed successfully ==="
    log_info "Transfer deepx-release.tar.gz to your board and run install.sh"
}

main "$@"
