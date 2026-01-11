#!/bin/sh
#
# DeepX DX-M1 Installation Script for iMDT V2H SBC
# Run this script on the board after transferring the release package
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KERNEL_VERSION="5.10.145-cip17-yocto-standard"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo "${RED}[ERROR]${NC} $1"; }

check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

check_kernel() {
    CURRENT_KERNEL=$(uname -r)
    if [ "$CURRENT_KERNEL" != "$KERNEL_VERSION" ]; then
        log_warn "Kernel version mismatch!"
        log_warn "Expected: $KERNEL_VERSION"
        log_warn "Current:  $CURRENT_KERNEL"
        log_warn "Drivers may not load correctly"
    fi
}

check_pcie_device() {
    log_info "Checking for DeepX device on PCIe..."
    
    if lspci 2>/dev/null | grep -q "1ff4"; then
        log_info "DeepX device found on PCIe"
        return 0
    fi
    
    log_warn "DeepX device not detected, attempting M.2 slot reset..."
    
    # Export GPIO for M.2 reset if not already done
    if [ ! -d /sys/class/gpio/gpio979 ]; then
        echo 979 > /sys/class/gpio/export 2>/dev/null || true
    fi
    
    # Configure as output
    echo out > /sys/class/gpio/gpio979/direction 2>/dev/null || true
    
    # Reset sequence
    echo 0 > /sys/class/gpio/gpio979/value
    sleep 1
    echo 1 > /sys/class/gpio/gpio979/value
    sleep 2
    
    # Check again
    if lspci 2>/dev/null | grep -q "1ff4"; then
        log_info "DeepX device found after reset"
        return 0
    fi
    
    log_error "DeepX device still not detected. Please check hardware connection."
    return 1
}

install_drivers() {
    log_info "Installing DeepX drivers..."
    
    DRIVER_DIR="$SCRIPT_DIR/drivers"
    MODULE_DIR="/lib/modules/$KERNEL_VERSION/extra"
    
    # Create module directory
    mkdir -p "$MODULE_DIR"
    
    # Copy driver modules
    cp "$DRIVER_DIR/dxrt_driver.ko" "$MODULE_DIR/"
    cp "$DRIVER_DIR/dx_dma.ko" "$MODULE_DIR/"
    
    # Copy DMA config
    mkdir -p /etc/modprobe.d
    cp "$DRIVER_DIR/dx_dma.conf" /etc/modprobe.d/
    
    # Update module dependencies
    /sbin/depmod -a
    
    # Create autoload config
    mkdir -p /etc/modules-load.d
    cat > /etc/modules-load.d/deepx.conf << EOF
# DeepX DX-M1 drivers
dx_dma
dxrt_driver
EOF
    
    # Load drivers now
    /sbin/modprobe dx_dma || /sbin/insmod "$MODULE_DIR/dx_dma.ko"
    /sbin/modprobe dxrt_driver || /sbin/insmod "$MODULE_DIR/dxrt_driver.ko"
    
    # Verify
    if lsmod | grep -q dxrt_driver; then
        log_info "Drivers loaded successfully"
    else
        log_error "Failed to load drivers"
        return 1
    fi
    
    # Check device nodes
    sleep 1
    if [ -e /dev/dx0 ]; then
        log_info "Device node /dev/dx0 created"
    else
        log_warn "Device node /dev/dx0 not found"
    fi
}

install_runtime() {
    log_info "Installing DeepX runtime..."
    
    RUNTIME_DIR="$SCRIPT_DIR/runtime"
    
    # Create directories
    mkdir -p /usr/local/bin
    mkdir -p /usr/local/lib
    
    # Install binaries
    cp "$RUNTIME_DIR/bin/dxrt-cli" /usr/local/bin/
    cp "$RUNTIME_DIR/bin/dxrtd" /usr/local/bin/
    cp "$RUNTIME_DIR/bin/dxtop" /usr/local/bin/ 2>/dev/null || true
    
    chmod +x /usr/local/bin/dxrt-cli
    chmod +x /usr/local/bin/dxrtd
    chmod +x /usr/local/bin/dxtop 2>/dev/null || true
    
    # Install libraries
    cp "$RUNTIME_DIR/lib/"*.so* /usr/local/lib/
    
    # Update library cache
    echo "/usr/local/lib" > /etc/ld.so.conf.d/deepx.conf
    /sbin/ldconfig 2>/dev/null || true
    
    # Add to PATH if not already there
    if ! grep -q "/usr/local/bin" /etc/profile 2>/dev/null; then
        echo 'export PATH=/usr/local/bin:$PATH' >> /etc/profile
    fi
    
    # Add library path
    if ! grep -q "/usr/local/lib" /etc/profile 2>/dev/null; then
        echo 'export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH' >> /etc/profile
    fi
    
    log_info "Runtime installed successfully"
}

verify_installation() {
    log_info "Verifying installation..."
    
    export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
    export PATH=/usr/local/bin:$PATH
    
    if /usr/local/bin/dxrt-cli -s; then
        log_info "=== Installation completed successfully! ==="
        return 0
    else
        log_error "Verification failed"
        return 1
    fi
}

main() {
    echo "=============================================="
    echo " DeepX DX-M1 Installer for iMDT V2H SBC"
    echo "=============================================="
    echo ""
    
    check_root
    check_kernel
    check_pcie_device
    install_drivers
    install_runtime
    verify_installation
    
    echo ""
    echo "=============================================="
    echo " Installation Complete!"
    echo "=============================================="
    echo ""
    echo "You can now use the following commands:"
    echo "  dxrt-cli -s    # Check device status"
    echo "  dxtop          # Monitor NPU usage"
    echo ""
    echo "Note: Run 'source /etc/profile' or log out/in"
    echo "      to update your PATH and LD_LIBRARY_PATH"
    echo ""
}

main "$@"
