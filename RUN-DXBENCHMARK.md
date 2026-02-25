# Running dxbenchmark on iMDT V2H SBC

## Current Status
Your DeepX AI accelerator is properly detected:
```
01:00.0 Processing accelerators: Device 1ff4:0000 (rev 01)
```

## Prerequisites Check

On the board, verify the DeepX runtime is installed:

```bash
# Check if drivers are loaded
lsmod | grep dx

# Check device status
dxrt-cli -s

# Verify dxbenchmark binary exists
which dxbenchmark
# OR
ls -la /opt/deepx/bin/dxbenchmark
```

## Installation Steps

### 1. Transfer Required Files to Board

From your host PC, transfer the runtime and models:

```bash
# Set your board IP
BOARD_IP=10.11.12.79  # Adjust to your board's IP

# Transfer DeepX runtime binaries
scp dxrt-arm64-bin.tar.gz root@${BOARD_IP}:/tmp/

# Transfer model files
scp models.tar.gz root@${BOARD_IP}:/tmp/

# Transfer examples (optional)
scp dxrt-examples.tar.gz root@${BOARD_IP}:/tmp/
```

### 2. Install on Board

SSH into the board and run:

```bash
# Extract DeepX runtime
cd /opt
mkdir -p deepx
cd /tmp
tar xzf dxrt-arm64-bin.tar.gz -C /opt/deepx/

# Add to PATH
export PATH=/opt/deepx/bin:$PATH
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH

# Make permanent (add to ~/.bashrc or /etc/profile)
echo 'export PATH=/opt/deepx/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH' >> ~/.bashrc

# Extract models
mkdir -p /opt/deepx/models
tar xzf /tmp/models.tar.gz -C /opt/deepx/models/

# Extract examples (optional)
tar xzf /tmp/dxrt-examples.tar.gz -C /opt/deepx/
```

## Running dxbenchmark

### Basic Usage

```bash
# Run benchmark on a single model (10 second duration)
dxbenchmark --dir /opt/deepx/models/resnet50 --time 10

# Run benchmark with specific number of loops
dxbenchmark --dir /opt/deepx/models/resnet50 --loops 100

# Run on all models in directory
dxbenchmark --dir /opt/deepx/models --time 10 --recursive
```

### Advanced Options

```bash
# Use specific NPU (0, 1, or 2)
dxbenchmark --dir /opt/deepx/models/resnet50 --time 10 --devices 0

# Use multiple NPUs
dxbenchmark --dir /opt/deepx/models/resnet50 --time 10 --devices 0,1,2

# Verbose output with detailed timing
dxbenchmark --dir /opt/deepx/models/resnet50 --time 10 --verbose

# Save results to specific path
dxbenchmark --dir /opt/deepx/models --time 10 --result-path /tmp/results

# Sort results by FPS (descending)
dxbenchmark --dir /opt/deepx/models --time 10 --sort fps --order desc
```

### NPU Binding Options

The `--npu` parameter controls NPU binding:
- `0`: NPU_ALL (use all 3 NPUs)
- `1`: NPU_0 only
- `2`: NPU_1 only
- `3`: NPU_2 only
- `4`: NPU_0/1
- `5`: NPU_1/2
- `6`: NPU_0/2

Example:
```bash
# Use all NPUs
dxbenchmark --dir /opt/deepx/models/resnet50 --time 10 --npu 0

# Use only NPU 0
dxbenchmark --dir /opt/deepx/models/resnet50 --time 10 --npu 1
```

## Expected Output

You should see output like:

```
Runtime Framework Version: v3.1.0
Device Driver Version: v1.8.0
PCIe Driver Version: v1.6.0

Device specification: 'all' (default)

Model: resnet50
  FPS: 245.6
  NPU Inference Time: 4.07 ms
  Latency: 4.12 ms
```

## Troubleshooting

### Driver Not Loaded
```bash
# Check kernel modules
lsmod | grep dx

# Load driver manually
modprobe dx_pcie
modprobe dx_npu
```

### Library Not Found
```bash
# Set library path
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH
```

### No Models Found
```bash
# Verify model directory structure
ls -la /opt/deepx/models/

# Models should be in .dxm format
find /opt/deepx/models -name "*.dxm"
```

### Permission Denied
```bash
# Make binary executable
chmod +x /opt/deepx/bin/dxbenchmark

# Run as root if needed
sudo dxbenchmark --dir /opt/deepx/models/resnet50 --time 10
```

## Quick Test Script

Save this as `/opt/deepx/test_inference.sh`:

```bash
#!/bin/bash
export PATH=/opt/deepx/bin:$PATH
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH

echo "=== DeepX Device Status ==="
dxrt-cli -s

echo ""
echo "=== Running Benchmark ==="
dxbenchmark --dir /opt/deepx/models --time 10 --verbose --sort fps --order desc
```

Make it executable:
```bash
chmod +x /opt/deepx/test_inference.sh
./opt/deepx/test_inference.sh
```

## Performance Monitoring

Monitor NPU utilization during inference:

```bash
# In another terminal, run:
watch -n 1 dxrt-cli -s

# Or use dxtop for real-time monitoring
dxtop
```

## Notes

- The board has 3 NPUs that can run in parallel
- Models must be in DeepX `.dxm` format
- Warmup iterations (default: 10) are run before benchmarking
- Results are saved as CSV and JSON in the result-path directory
