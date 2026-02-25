#!/bin/sh
# DeepX AI Inference Test Script

echo "========================================"
echo "  DeepX AI Inference Test"
echo "========================================"
echo ""

# Setup environment
export PATH=/opt/deepx/bin:/bin:/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH

# Check drivers
echo "1. Checking drivers..."
if lsmod | grep -q dx_dma; then
    echo "  ✓ dx_dma loaded"
else
    echo "  ✗ dx_dma not loaded"
    exit 1
fi

if lsmod | grep -q dxrt_driver; then
    echo "  ✓ dxrt_driver loaded"
else
    echo "  ✗ dxrt_driver not loaded"
    exit 1
fi
echo ""

# Check service
echo "2. Checking service..."
if /etc/init.d/deepx-ai status >/dev/null 2>&1; then
    echo "  ✓ DeepX service running"
else
    echo "  ⚠ Service not running, starting..."
    /etc/init.d/deepx-ai start
    sleep 2
fi
echo ""

# Check device
echo "3. Checking device status..."
dxrt-cli -s
echo ""

# Run inference test
echo "4. Running inference test (10 seconds)..."
echo ""

# Create test directory
mkdir -p /tmp/deepx-test
cp /opt/deepx/models/YoloV8N.dxnn /tmp/deepx-test/ 2>/dev/null || \
cp /opt/deepx/models/EfficientNetB0_4.dxnn /tmp/deepx-test/ 2>/dev/null || \
cp /opt/deepx/models/*.dxnn /tmp/deepx-test/ 2>/dev/null | head -1

# Find a model to test
TEST_MODEL=$(find /tmp/deepx-test -name "*.dxnn" | head -1)

if [ -z "$TEST_MODEL" ]; then
    echo "  ✗ No models found for testing"
    exit 1
fi

echo "Testing with: $(basename $TEST_MODEL)"
echo ""

# Run inference
run_model --model "$TEST_MODEL" --time 10 --verbose

echo ""
echo "========================================"
echo "  Test Complete!"
echo "========================================"
echo ""
echo "If you see FPS > 40, the system is working correctly."
echo ""
echo "To benchmark all models:"
echo "  dxbenchmark --dir /opt/deepx/models --time 10 --verbose --sort fps --order desc"
echo ""
