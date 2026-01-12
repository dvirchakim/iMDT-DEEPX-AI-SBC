# iMDT V2H DeepX AI SBC - DeepX DX-M1 Installation Guide

This repository provides automated scripts and documentation for installing the DeepX DX-M1 AI accelerator on the iMDT V2H Single Board Computer.

<img width="595" height="511" alt="image" src="https://github.com/user-attachments/assets/15fe7031-17ff-419b-a70d-c588cc599106" />

## Hardware Requirements

- **Board**: iMDT V2H SBC (Renesas RZ/V2H based)
- **AI Accelerator**: DeepX DX-M1 M.2 module
- **Host PC**: Windows/Linux with Docker installed (for cross-compilation)

## Board Specifications

| Component | Details |
|-----------|---------|
| SoC | Renesas RZ/V2H |
| Architecture | ARM64 (aarch64) |
| Kernel | 5.10.145-cip17-yocto-standard |
| glibc | 2.28 |

## Quick Start

### Option 1: Pre-built Binaries (Recommended)

If you have the pre-built binaries, simply run on the board:

```bash
# Transfer the release package to the board
scp deepx-release.tar.gz root@<board-ip>:/tmp/

# SSH into the board
ssh root@<board-ip>

# Run the installer
cd /tmp
tar xzf deepx-release.tar.gz
cd deepx-release
./install.sh
```

### Option 2: Build from Source

On your host PC with Docker:

```bash
# Clone this repository
git clone https://github.com/dvirchakim/iMDT-DEEPX-AI-SBC.git
cd iMDT-DEEPX-AI-SBC

# Build everything (drivers + runtime)
./build.sh

# Transfer to board and install
./deploy.sh <board-ip>
```

## Manual Installation Steps

### Step 1: Connect Board to Network

```bash
# On the board, connect to WiFi
/opt/imdt/wifi/connect-to-access-point.sh "YOUR_SSID" "YOUR_PASSWORD"

# Check IP address
ip addr show wlan0
```

### Step 2: Install DeepX Drivers

The drivers must be cross-compiled on a host PC since the board lacks build tools.

```bash
# On host PC with Docker
cd drivers
./build-drivers.sh

# Transfer to board
scp drivers.tar.gz root@<board-ip>:/tmp/

# On the board
cd /tmp
tar xzf drivers.tar.gz
./install-drivers.sh
```

### Step 3: Install DeepX Runtime (DX-RT)

```bash
# On host PC with Docker
cd runtime
./build-runtime.sh

# Transfer to board
scp dxrt-arm64.tar.gz root@<board-ip>:/tmp/

# On the board
cd /tmp
tar xzf dxrt-arm64.tar.gz
./install-runtime.sh
```

### Step 4: Verify Installation

```bash
# Check driver is loaded
lsmod | grep dx

# Check device status
dxrt-cli -s
```

Expected output:
```
DXRT v3.1.0
=======================================================
 * Device 0: M1, Accelerator type
---------------------   Version   ---------------------
 * RT Driver version   : v1.8.0
 * PCIe Driver version : v1.6.0
-------------------------------------------------------
 * FW version          : v2.4.0
--------------------- Device Info ---------------------
 * Memory : LPDDR5 5600 Mbps, 3.92GiB
 * Board  : M.2, Rev 1.0
 * PCIe   : Gen3 X4 [01:00:00]

NPU 0: voltage 750 mV, clock 1000 MHz, temperature 48'C
NPU 1: voltage 750 mV, clock 1000 MHz, temperature 47'C
NPU 2: voltage 750 mV, clock 1000 MHz, temperature 47'C
=======================================================
```

## Running AI Demos with Camera

After installing the drivers and runtime, you can run AI inference demos using a USB camera:

```bash
# Transfer the DX-APP package to the board
scp dx_app_arm64.tar.gz root@<board-ip>:/tmp/

# On the board
cd /tmp
tar xzf dx_app_arm64.tar.gz
cd dx_app_package

# Start the dxrtd service
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
nohup /usr/local/bin/dxrtd > /tmp/dxrtd.log 2>&1 &

# Run camera inference
./run_camera_inference.sh
```

### Available Models

| Model | Type | Description |
|-------|------|-------------|
| YOLOv7 | Object Detection | 80 classes (COCO) |
| YOLOv8N | Object Detection | Fast, lightweight |
| YOLOv5S | Object Detection | Balanced speed/accuracy |
| YOLOv5S_Face | Face Detection | Optimized for faces |
| YOLOV5Pose | Pose Estimation | Human keypoints |
| DeepLabV3+ | Segmentation | Semantic segmentation |

### Single Image Inference

```bash
# Capture a frame from camera
gst-launch-1.0 v4l2src device=/dev/video2 num-buffers=1 ! videoconvert ! jpegenc ! filesink location=/tmp/frame.jpg

# Run inference
cd /tmp/dx_app_package
export LD_LIBRARY_PATH=/tmp/dx_app_package/lib:/usr/local/lib:$LD_LIBRARY_PATH
./bin/yolo -m assets/models/YoloV7.dxnn -p 4 -i /tmp/frame.jpg --fps_only
```

## Repository Structure

```
iMDT-DEEPX-AI-SBC/
├── README.md                 # This file
├── build.sh                  # Main build script (host PC)
├── build.cmd                 # Windows build script
├── deploy.sh                 # Deploy to board script
├── docker/
│   ├── Dockerfile.drivers    # Docker image for driver compilation
│   ├── Dockerfile.runtime    # Docker image for runtime compilation
│   └── Dockerfile.dxapp      # Docker image for DX-APP compilation
├── scripts/
│   ├── build-dxapp.sh        # Build DX-APP demos
│   └── run_camera_inference.sh # Camera inference script
├── board/
│   └── install.sh            # All-in-one installer for board
└── docs/
    ├── TROUBLESHOOTING.md    # Common issues and solutions
    └── ARCHITECTURE.md       # Technical details
```

## Troubleshooting

### PCIe Device Not Detected

```bash
# Check if device is visible
lspci | grep -i 1ff4

# If not visible, try resetting the M.2 slot
echo 0 > /sys/class/gpio/gpio979/value
sleep 1
echo 1 > /sys/class/gpio/gpio979/value
sleep 2
lspci | grep -i 1ff4
```

### Driver Loading Fails

```bash
# Check kernel messages
dmesg | grep -i deepx

# Verify kernel version matches
uname -r
# Should be: 5.10.145-cip17-yocto-standard
```

### glibc Version Mismatch

If you see errors like `GLIBC_2.34 not found`, the binaries were compiled with a newer toolchain. Rebuild using Ubuntu 18.04 Docker image.

## Dependencies

### Host PC (for building)
- Docker
- Git

### Board
- Network connectivity (WiFi or Ethernet)
- Root access

## License

This project provides installation scripts and documentation. The DeepX SDK and drivers are subject to DeepX's licensing terms.

## References

- [DeepX DX-ALL-SUITE](https://github.com/DEEPX-AI/dx-all-suite)
- [DeepX NPU Linux Driver](https://github.com/DEEPX-AI/dx_rt_npu_linux_driver)
- [iMDT V2H SBC Documentation](https://wiki.imd-tec.com/)
