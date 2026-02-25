#!/bin/bash
# Setup script for dxbenchmark on iMDT V2H SBC
# Run this script on the board after transferring the tar.gz files

set -e

echo "=== DeepX Benchmark Setup Script ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo or login as root)"
    exit 1
fi

# Configuration
DEEPX_ROOT="/opt/deepx"
TMP_DIR="/tmp"

echo "Step 1: Creating directory structure..."
mkdir -p ${DEEPX_ROOT}/{bin,lib,models,examples}

# Check if runtime archive exists
if [ -f "${TMP_DIR}/dxrt-arm64-bin.tar.gz" ]; then
    echo "Step 2: Extracting DeepX runtime..."
    tar xzf ${TMP_DIR}/dxrt-arm64-bin.tar.gz -C ${DEEPX_ROOT}/
    echo "  ✓ Runtime extracted"
else
    echo "  ⚠ Warning: dxrt-arm64-bin.tar.gz not found in ${TMP_DIR}"
    echo "    Please transfer it first: scp dxrt-arm64-bin.tar.gz root@<board-ip>:/tmp/"
fi

# Check if models archive exists
if [ -f "${TMP_DIR}/models.tar.gz" ]; then
    echo "Step 3: Extracting models..."
    tar xzf ${TMP_DIR}/models.tar.gz -C ${DEEPX_ROOT}/models/
    echo "  ✓ Models extracted"
else
    echo "  ⚠ Warning: models.tar.gz not found in ${TMP_DIR}"
    echo "    Please transfer it first: scp models.tar.gz root@<board-ip>:/tmp/"
fi

# Check if examples archive exists
if [ -f "${TMP_DIR}/dxrt-examples.tar.gz" ]; then
    echo "Step 4: Extracting examples..."
    tar xzf ${TMP_DIR}/dxrt-examples.tar.gz -C ${DEEPX_ROOT}/examples/
    echo "  ✓ Examples extracted"
else
    echo "  ℹ Info: dxrt-examples.tar.gz not found (optional)"
fi

echo ""
echo "Step 5: Setting up environment..."

# Create environment setup script
cat > ${DEEPX_ROOT}/setup_env.sh << 'EOF'
#!/bin/bash
export PATH=/opt/deepx/bin:$PATH
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH
EOF

chmod +x ${DEEPX_ROOT}/setup_env.sh

# Add to system profile
if ! grep -q "deepx/setup_env.sh" /etc/profile; then
    echo "source /opt/deepx/setup_env.sh" >> /etc/profile
    echo "  ✓ Added to /etc/profile"
fi

# Add to root's bashrc
if [ -f /root/.bashrc ]; then
    if ! grep -q "deepx/setup_env.sh" /root/.bashrc; then
        echo "source /opt/deepx/setup_env.sh" >> /root/.bashrc
        echo "  ✓ Added to /root/.bashrc"
    fi
fi

# Source it now
source ${DEEPX_ROOT}/setup_env.sh

echo ""
echo "Step 6: Verifying installation..."

# Check for dxbenchmark binary
if [ -f "${DEEPX_ROOT}/bin/dxbenchmark" ]; then
    chmod +x ${DEEPX_ROOT}/bin/dxbenchmark
    echo "  ✓ dxbenchmark binary found"
else
    echo "  ✗ dxbenchmark binary not found!"
    echo "    Expected at: ${DEEPX_ROOT}/bin/dxbenchmark"
fi

# Check for dxrt-cli
if [ -f "${DEEPX_ROOT}/bin/dxrt-cli" ]; then
    chmod +x ${DEEPX_ROOT}/bin/dxrt-cli
    echo "  ✓ dxrt-cli binary found"
else
    echo "  ✗ dxrt-cli binary not found!"
fi

# Check for libraries
LIB_COUNT=$(find ${DEEPX_ROOT}/lib -name "*.so*" 2>/dev/null | wc -l)
if [ $LIB_COUNT -gt 0 ]; then
    echo "  ✓ Found ${LIB_COUNT} library files"
else
    echo "  ⚠ Warning: No library files found in ${DEEPX_ROOT}/lib"
fi

# Check for models
MODEL_COUNT=$(find ${DEEPX_ROOT}/models -name "*.dxm" 2>/dev/null | wc -l)
if [ $MODEL_COUNT -gt 0 ]; then
    echo "  ✓ Found ${MODEL_COUNT} model files"
else
    echo "  ⚠ Warning: No .dxm model files found in ${DEEPX_ROOT}/models"
fi

echo ""
echo "Step 7: Checking DeepX device..."

# Check PCIe device
if lspci | grep -q "1ff4:0000"; then
    echo "  ✓ DeepX PCIe device detected"
else
    echo "  ✗ DeepX PCIe device NOT detected!"
    echo "    Run: lspci"
fi

# Check driver
if lsmod | grep -q "dx"; then
    echo "  ✓ DeepX driver loaded"
    lsmod | grep dx
else
    echo "  ⚠ DeepX driver not loaded"
    echo "    Try: modprobe dx_pcie && modprobe dx_npu"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "To use DeepX tools, run:"
echo "  source /opt/deepx/setup_env.sh"
echo ""
echo "Or simply log out and log back in (environment is auto-loaded)"
echo ""
echo "Quick test commands:"
echo "  dxrt-cli -s                    # Check device status"
echo "  dxbenchmark --help             # Show benchmark options"
echo ""
echo "Example benchmark:"
echo "  dxbenchmark --dir /opt/deepx/models --time 10 --verbose"
echo ""
