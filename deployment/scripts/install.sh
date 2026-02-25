#!/bin/sh
# DeepX AI Deployment Installer
# Version: 1.0
# For: iMDT V2H SBC with DeepX M1 Accelerator

set -e

echo "========================================"
echo "  DeepX AI Deployment Installer v1.0"
echo "========================================"
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"

echo "Deployment directory: $DEPLOY_DIR"
echo ""

# Verify package contents
echo "Step 1: Verifying package contents..."
MISSING=0

if [ ! -f "$DEPLOY_DIR/drivers/dx_dma.ko" ]; then
    echo "  ✗ Missing: drivers/dx_dma.ko"
    MISSING=1
fi

if [ ! -f "$DEPLOY_DIR/drivers/dxrt_driver.ko" ]; then
    echo "  ✗ Missing: drivers/dxrt_driver.ko"
    MISSING=1
fi

if [ ! -f "$DEPLOY_DIR/runtime/dxrt-arm64-bin.tar.gz" ]; then
    echo "  ✗ Missing: runtime/dxrt-arm64-bin.tar.gz"
    MISSING=1
fi

if [ ! -f "$DEPLOY_DIR/firmware/fw-2.5.0.bin" ]; then
    echo "  ✗ Missing: firmware/fw-2.5.0.bin"
    MISSING=1
fi

if [ ! -f "$DEPLOY_DIR/models/models.tar.gz" ]; then
    echo "  ✗ Missing: models/models.tar.gz"
    MISSING=1
fi

if [ $MISSING -eq 1 ]; then
    echo ""
    echo "Error: Package is incomplete. Please check the deployment package."
    exit 1
fi

echo "  ✓ All required files present"
echo ""

# Install kernel drivers
echo "Step 2: Installing kernel drivers..."
KERNEL_VER="5.10.145-cip17-yocto-standard"
MODULE_DIR="/lib/modules/${KERNEL_VER}/extra"

mkdir -p ${MODULE_DIR}
cp -v "$DEPLOY_DIR/drivers/dx_dma.ko" ${MODULE_DIR}/
cp -v "$DEPLOY_DIR/drivers/dxrt_driver.ko" ${MODULE_DIR}/
echo "  ✓ Drivers installed to ${MODULE_DIR}"
echo ""

# Install DeepX runtime
echo "Step 3: Installing DeepX runtime..."
mkdir -p /opt/deepx
tar xzf "$DEPLOY_DIR/runtime/dxrt-arm64-bin.tar.gz" -C /opt/deepx/
echo "  ✓ Runtime installed to /opt/deepx"
echo ""

# Load drivers for firmware update
echo "Step 4: Loading drivers..."
/sbin/insmod ${MODULE_DIR}/dx_dma.ko 2>/dev/null || echo "  (dx_dma already loaded)"
/sbin/insmod ${MODULE_DIR}/dxrt_driver.ko 2>/dev/null || echo "  (dxrt_driver already loaded)"

if lsmod | grep -q dx_dma; then
    echo "  ✓ Drivers loaded successfully"
else
    echo "  ✗ Failed to load drivers"
    exit 1
fi
echo ""

# Update firmware
echo "Step 5: Updating firmware to v2.5.0..."
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH
/opt/deepx/bin/dxrt-cli -u "$DEPLOY_DIR/firmware/fw-2.5.0.bin"
echo "  ✓ Firmware updated"
echo ""

# Install models
echo "Step 6: Installing AI models..."
mkdir -p /opt/deepx/models
tar xzf "$DEPLOY_DIR/models/models.tar.gz" -C /opt/deepx/models/
MODEL_COUNT=$(find /opt/deepx/models -name "*.dxnn" 2>/dev/null | wc -l)
echo "  ✓ Installed $MODEL_COUNT models"
echo ""

# Configure auto-start
echo "Step 7: Configuring auto-start..."

# Copy init script
cp -v "$DEPLOY_DIR/scripts/deepx-ai-init" /etc/init.d/deepx-ai
chmod +x /etc/init.d/deepx-ai
echo "  ✓ Init script installed"

# Create rc.local
cat > /etc/rc.local << 'EOF'
#!/bin/sh
/etc/init.d/deepx-ai start
exit 0
EOF
chmod +x /etc/rc.local
echo "  ✓ Auto-start configured"

# Create environment script
cat > /etc/profile.d/deepx.sh << 'EOF'
export PATH="/opt/deepx/bin:${PATH}"
export LD_LIBRARY_PATH="/opt/deepx/lib:${LD_LIBRARY_PATH}"
EOF
chmod +x /etc/profile.d/deepx.sh
echo "  ✓ Environment configured"

# Create symlinks for auto-start
ln -sf /etc/init.d/deepx-ai /etc/rc5.d/S99deepx-ai 2>/dev/null || true
ln -sf /etc/init.d/deepx-ai /etc/rc0.d/K01deepx-ai 2>/dev/null || true
echo "  ✓ Auto-start symlinks created"
echo ""

# Installation summary
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
echo ""
echo "Installed components:"
echo "  ✓ Kernel drivers (dx_dma, dxrt_driver)"
echo "  ✓ DeepX Runtime v3.1.0"
echo "  ✓ Firmware v2.5.0"
echo "  ✓ $MODEL_COUNT AI models"
echo "  ✓ Auto-start service"
echo ""
echo "IMPORTANT: Reboot required for firmware update"
echo ""
echo "Next steps:"
echo "  1. Reboot the board:"
echo "     /sbin/reboot"
echo ""
echo "  2. After reboot (~60 seconds), verify:"
echo "     dxrt-cli -s"
echo ""
echo "  3. Run test inference:"
echo "     cd $DEPLOY_DIR/scripts"
echo "     ./test-inference.sh"
echo ""
echo "The system will auto-start on every boot."
echo ""
