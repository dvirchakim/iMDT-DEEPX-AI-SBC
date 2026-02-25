#!/bin/bash
# Quick benchmark runner for iMDT V2H SBC
# Usage: ./run_benchmark.sh [model_dir] [duration]

# Setup environment
export PATH=/opt/deepx/bin:$PATH
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH

# Default values
MODEL_DIR="${1:-/opt/deepx/models}"
DURATION="${2:-10}"
RESULT_DIR="/tmp/benchmark_results_$(date +%Y%m%d_%H%M%S)"

echo "========================================"
echo "  DeepX AI Benchmark Runner"
echo "========================================"
echo ""
echo "Configuration:"
echo "  Model Directory: ${MODEL_DIR}"
echo "  Duration: ${DURATION} seconds"
echo "  Result Directory: ${RESULT_DIR}"
echo ""

# Create results directory
mkdir -p ${RESULT_DIR}

# Check device status first
echo "=== Device Status ==="
if command -v dxrt-cli &> /dev/null; then
    dxrt-cli -s
else
    echo "Error: dxrt-cli not found!"
    echo "Please run: source /opt/deepx/setup_env.sh"
    exit 1
fi

echo ""
echo "=== Starting Benchmark ==="
echo ""

# Check if dxbenchmark exists
if ! command -v dxbenchmark &> /dev/null; then
    echo "Error: dxbenchmark not found!"
    echo "Please ensure DeepX runtime is installed in /opt/deepx"
    exit 1
fi

# Check if model directory exists
if [ ! -d "${MODEL_DIR}" ]; then
    echo "Error: Model directory not found: ${MODEL_DIR}"
    echo ""
    echo "Available models:"
    find /opt/deepx/models -name "*.dxm" 2>/dev/null || echo "  No models found!"
    exit 1
fi

# Count models
MODEL_COUNT=$(find ${MODEL_DIR} -name "*.dxm" 2>/dev/null | wc -l)
echo "Found ${MODEL_COUNT} model(s) in ${MODEL_DIR}"
echo ""

# Run benchmark with all NPUs, verbose output, sorted by FPS
dxbenchmark \
    --dir "${MODEL_DIR}" \
    --time ${DURATION} \
    --warmup 10 \
    --devices all \
    --verbose \
    --sort fps \
    --order desc \
    --result-path "${RESULT_DIR}" \
    --recursive

echo ""
echo "=== Benchmark Complete ==="
echo ""
echo "Results saved to: ${RESULT_DIR}"
echo ""

# Show result files
if [ -d "${RESULT_DIR}" ]; then
    echo "Generated files:"
    ls -lh ${RESULT_DIR}/
    echo ""
    
    # Show CSV if exists
    CSV_FILE=$(find ${RESULT_DIR} -name "*.csv" | head -1)
    if [ -f "${CSV_FILE}" ]; then
        echo "=== Performance Summary (CSV) ==="
        cat "${CSV_FILE}"
        echo ""
    fi
fi

echo "To view detailed results:"
echo "  cat ${RESULT_DIR}/*.csv"
echo "  cat ${RESULT_DIR}/*.json"
echo ""
