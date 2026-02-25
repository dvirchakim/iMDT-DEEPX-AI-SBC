# iMDT V2H Board Examination Report
**Board IP:** 192.168.0.165  
**Date:** February 25, 2026

## ✅ Hardware Status

### PCIe Device Detection
```
01:00.0 Processing accelerators: Device 1ff4:0000 (rev 01)
```
**Status:** ✅ DeepX AI accelerator detected successfully

### Device Information (via dxrt-cli)
```
DXRT v3.1.0
=======================================================
 * Device 0: M1, Accelerator type
---------------------   Version   ---------------------
 * RT Driver version   : v1.8.0
 * PCIe Driver version : v1.6.0
-------------------------------------------------------
 * FW version          : v2.1.0
--------------------- Device Info ---------------------
 * Memory : LPDDR5 5600 Mbps, 3.92GiB
 * Board  : M.2, Rev 1.5
 * Chip Offset : 0
 * PCIe   : Gen3 X4 [01:00:00]

NPU 0: voltage 750 mV, clock 1000 MHz, temperature 49'C
NPU 1: voltage 750 mV, clock 1000 MHz, temperature 49'C
NPU 2: voltage 750 mV, clock 1000 MHz, temperature 49'C
=======================================================
```

**Hardware Summary:**
- ✅ 3x NPUs operational at 1000 MHz
- ✅ 3.92 GiB LPDDR5 memory
- ✅ PCIe Gen3 X4 connection active
- ✅ All NPUs running at normal temperature (~49°C)

## ✅ Software Installation

### Kernel & Drivers
- **Kernel:** 5.10.145-cip17-yocto-standard
- **Architecture:** aarch64 (ARM64)
- **Drivers:** ✅ Successfully cross-compiled and loaded
  - `dx_dma.ko` (132.82 KB) - v1.6.0
  - `dxrt_driver.ko` (88.33 KB) - v1.8.0

### DeepX Runtime
- **Location:** `/opt/deepx/`
- **Runtime Version:** v3.1.0
- **Binaries Installed:**
  - ✅ dxrt-cli
  - ✅ dxbenchmark
  - ✅ dxrtd (service)
  - ✅ run_model and other utilities

### Models
- **Location:** `/opt/deepx/models/`
- **Count:** 25 models (.dxnn format)
- **Models Available:**
  - YOLOv5 variants (S, X, Pose, Face)
  - YOLOv7, YOLOv8, YOLOv9
  - YOLOv3, YOLOv4, YOLOX
  - EfficientNet B0
  - MobileNetV2
  - DeepLabV3Plus
  - SCRFD face detection
  - OSNet re-identification

## ⚠️ Current Issue: Firmware Version Mismatch

### Problem
The DeepX runtime v3.1.0 requires firmware v2.4.0 or higher, but the board currently has firmware v2.1.0.

**Error Message:**
```
[dxrt-exception] Invalid operation exception {
  "The current firmware version is 2.1.0.
   Please update your firmware to version 2.4.0 or higher."
} error-code=261
```

### Impact
- ✅ Device detection works
- ✅ Driver communication works
- ✅ dxrt-cli status works
- ❌ Model inference blocked by firmware check

## 🔧 Solutions

### Option 1: Update Firmware (Recommended)
Update the DeepX M1 accelerator firmware from v2.1.0 to v2.4.0+

**Steps needed:**
1. Obtain firmware update package from DeepX
2. Use firmware update utility to flash new firmware
3. Reboot board
4. Verify with `dxrt-cli -s`

### Option 2: Use Compatible Runtime Version
Downgrade the DeepX runtime to a version compatible with firmware v2.1.0

**Steps needed:**
1. Find runtime version that supports firmware v2.1.0
2. Replace `/opt/deepx/` binaries with compatible version
3. Test inference

### Option 3: Bypass Firmware Check (Development Only)
Modify runtime to skip firmware version check (not recommended for production)

## 📊 System Resources

```
Total Physical Memory: 14.86 GB
Available Memory: 11.94 GB
Total Swap: 0 GB
```

## 🚀 Quick Start Commands

### Environment Setup
```bash
export PATH=/opt/deepx/bin:$PATH
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH
```

### Start DeepX Service
```bash
# Start in background
nohup /opt/deepx/bin/dxrtd > /var/log/dxrtd.log 2>&1 &
```

### Check Device Status
```bash
dxrt-cli -s
```

### Run Inference (after firmware update)
```bash
# Single model benchmark
run_model --model /opt/deepx/models/YOLOV5S_1.dxnn --time 10 --verbose

# Multiple models benchmark
dxbenchmark --dir /opt/deepx/models --time 10 --verbose --sort fps --order desc
```

## 📁 File Locations

| Component | Path |
|-----------|------|
| DeepX Runtime | `/opt/deepx/` |
| Binaries | `/opt/deepx/bin/` |
| Libraries | `/opt/deepx/lib/` |
| Models | `/opt/deepx/models/` |
| Drivers (source) | `/tmp/dx_dma.ko`, `/tmp/dxrt_driver.ko` |
| Kernel Modules | `/lib/modules/5.10.145-cip17-yocto-standard/extra/` |

## 🔄 Auto-Load Drivers on Boot

To make drivers load automatically on boot:

```bash
# Copy drivers to kernel modules directory
cp /tmp/dx_dma.ko /lib/modules/5.10.145-cip17-yocto-standard/extra/
cp /tmp/dxrt_driver.ko /lib/modules/5.10.145-cip17-yocto-standard/extra/

# Update module dependencies
depmod -a

# Create module loading configuration
cat > /etc/modules-load.d/deepx.conf << EOF
dx_dma
dxrt_driver
EOF
```

## 📝 Next Steps

1. **Immediate:** Contact DeepX support for firmware v2.4.0 update package
2. **Alternative:** Request runtime binaries compatible with firmware v2.1.0
3. **After firmware update:** Run full benchmark suite on all 25 models
4. **Production:** Set up auto-start for dxrtd service

## 🛠️ Build Environment

The drivers were successfully cross-compiled using:
- **Docker Image:** deepx-driver-builder (Ubuntu 22.04)
- **Cross Compiler:** aarch64-linux-gnu-gcc
- **Kernel Source:** `/kernel-src` (5.10.145-cip17-yocto-standard)
- **Build Output:** `compiled_drivers/`

## ✅ Achievements

1. ✅ Successfully examined board hardware
2. ✅ Cross-compiled DeepX drivers for exact kernel version
3. ✅ Loaded drivers and verified device detection
4. ✅ Installed DeepX runtime v3.1.0
5. ✅ Transferred 25 AI models to board
6. ✅ Started dxrtd service successfully
7. ✅ Identified firmware version mismatch as blocker

## 📞 Support Information

**DeepX Support:** Contact for firmware v2.4.0 update  
**Repository:** https://github.com/dvirchakim/iMDT-DEEPX-AI-SBC  
**Board Model:** iMDT V2H with DeepX M1 accelerator
