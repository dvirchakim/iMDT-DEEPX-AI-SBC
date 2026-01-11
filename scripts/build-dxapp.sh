#!/bin/bash
#
# Build DX-APP (DeepX Application Demos) for ARM64
# Run this on your host PC with Docker installed
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT_DIR/build"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed"
    exit 1
fi

# Build Docker image if needed
if ! docker image inspect dxapp-arm64-build &> /dev/null; then
    log_info "Building dxapp-arm64-build Docker image..."
    docker build -t dxapp-arm64-build -f "$ROOT_DIR/docker/Dockerfile.dxapp" "$ROOT_DIR/docker/"
fi

mkdir -p "$BUILD_DIR"

# Clone dx-all-suite if not present
if [ ! -d "$BUILD_DIR/dx-all-suite" ]; then
    log_info "Cloning dx-all-suite..."
    git clone --recurse-submodules https://github.com/DEEPX-AI/dx-all-suite.git "$BUILD_DIR/dx-all-suite"
fi

# Build DX-RT first (required for DX-APP)
log_info "Building DX-RT runtime..."
docker run --rm -v "$BUILD_DIR:/build" dxapp-arm64-build bash -c "
    cd /build/dx-all-suite/dx-runtime/dx_rt
    find . -type f \( -name '*.sh' -o -name '*.cmake' -o -name 'CMakeLists.txt' \) -exec sed -i 's/\r$//' {} \;
    
    # Disable ORT
    sed -i 's/option(USE_ORT \"Use ONNX Runtime\" ON)/option(USE_ORT \"Use ONNX Runtime\" OFF)/' cmake/dxrt.cfg.cmake
    
    rm -rf build_aarch64
    ./build.sh --arch aarch64 --type Release || true
    
    # Copy include files
    mkdir -p build_aarch64/include
    cp -r lib/include/* build_aarch64/include/
    cp -r extern/include/dxrt/extern build_aarch64/include/dxrt/
"

# Build DX-APP
log_info "Building DX-APP..."
docker run --rm -v "$BUILD_DIR:/build" dxapp-arm64-build bash -c "
    cd /build/dx-all-suite/dx-runtime/dx_app
    find . -type f \( -name '*.sh' -o -name '*.cmake' -o -name 'CMakeLists.txt' \) -exec sed -i 's/\r$//' {} \;
    
    # Update toolchain to use our paths
    cat > cmake/toolchain.aarch64.cmake << 'EOF'
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(onnxruntime_LIB_DIRS /usr/local/lib)
set(onnxruntime_INCLUDE_DIRS /usr/local/include/onnxruntime)

set(DXRT_INSTALLED_DIR /build/dx-all-suite/dx-runtime/dx_rt/build_aarch64)

SET(CMAKE_C_COMPILER      /usr/bin/aarch64-linux-gnu-gcc )
SET(CMAKE_CXX_COMPILER    /usr/bin/aarch64-linux-gnu-g++ )
SET(CMAKE_LINKER          /usr/bin/aarch64-linux-gnu-ld  )
SET(CMAKE_NM              /usr/bin/aarch64-linux-gnu-nm )
SET(CMAKE_OBJCOPY         /usr/bin/aarch64-linux-gnu-objcopy )
SET(CMAKE_OBJDUMP         /usr/bin/aarch64-linux-gnu-objdump )
SET(CMAKE_RANLIB          /usr/bin/aarch64-linux-gnu-ranlib )

set(OpenCV_DIR            /opt/opencv-aarch64/lib/cmake/opencv4)
EOF
    
    rm -rf build_aarch64
    ./build.sh --arch aarch64 || true
"

# Download models
log_info "Downloading models..."
docker run --rm -v "$BUILD_DIR:/build" dxapp-arm64-build bash -c "
    if [ ! -f /build/models.tar.gz ]; then
        wget -q https://sdk.deepx.ai/res/models/models-2_1_0.tar.gz -O /build/models.tar.gz
    fi
"

# Package everything
log_info "Creating package..."
docker run --rm -v "$BUILD_DIR:/build" -v "$ROOT_DIR:/repo" dxapp-arm64-build bash -c "
    cd /build
    rm -rf dx_app_package
    mkdir -p dx_app_package/bin dx_app_package/lib dx_app_package/assets/models
    
    # Copy binaries
    cp dx-all-suite/dx-runtime/dx_app/build_aarch64/release/bin/* dx_app_package/bin/
    
    # Copy libraries
    cp -r /opt/opencv-aarch64/lib/*.so* dx_app_package/lib/
    cp dx-all-suite/dx-runtime/dx_rt/build_aarch64/lib/*.so* dx_app_package/lib/
    
    # Extract models
    tar xzf models.tar.gz -C dx_app_package/assets/models/
    
    # Copy scripts
    cp /repo/scripts/run_camera_inference.sh dx_app_package/
    chmod +x dx_app_package/*.sh
    
    # Create tarball
    tar czf dx_app_arm64.tar.gz dx_app_package
    cp dx_app_arm64.tar.gz /repo/
"

log_info "Build complete: $ROOT_DIR/dx_app_arm64.tar.gz"
log_info ""
log_info "To deploy to board:"
log_info "  scp dx_app_arm64.tar.gz root@<board-ip>:/tmp/"
log_info "  ssh root@<board-ip> 'cd /tmp && tar xzf dx_app_arm64.tar.gz'"
