# DeepX AI Update & Inference Success Report

**Board:** iMDT V2H SBC @ 192.168.0.165  
**Date:** February 25, 2026  
**Status:** ✅ **FULLY OPERATIONAL**

---

## 🎯 Mission Accomplished

Successfully updated DeepX firmware and ran AI inference on the board!

### Firmware Update
- **Previous:** v2.1.0
- **Updated to:** v2.5.0 ✅
- **Method:** Used latest dx-all-suite from GitHub

### First Successful Inference Test

**Model:** YOLOv8N (Object Detection)  
**Test Duration:** 10 seconds  
**Results:**
```
Benchmark Result (553 inputs)
- NPU Processing Time Average: 9.571 ms
- Latency Average: 108.939 ms
- FPS: 54.72
- Total Loops: 553
```

**Performance Metrics:**
- ✅ 54.72 FPS on YOLOv8N
- ✅ ~9.6ms NPU processing time
- ✅ All 3 NPUs operational
- ✅ 145MB NPU memory usage

---

## 📊 Current System Status

### Hardware
```
Device: DeepX M1 Accelerator
Board: M.2, Rev 1.0
Memory: LPDDR5 5600 Mbps, 3.92GiB
PCIe: Gen3 X4 [01:00:00]

NPU 0: 750 mV, 1000 MHz, 49°C ✅
NPU 1: 750 mV, 1000 MHz, 48°C ✅
NPU 2: 750 mV, 1000 MHz, 48°C ✅
```

### Software
```
Runtime: DeepX RT v3.1.0
Firmware: v2.5.0
RT Driver: v1.8.0
PCIe Driver: v1.6.0
Kernel: 5.10.145-cip17-yocto-standard (aarch64)
```

### Available Models (25 total)
- YOLOv5 variants (S, X, Pose, Face)
- YOLOv7, YOLOv8N, YOLOv9S
- YOLOv3, YOLOv4, YOLOX-S
- EfficientNet B0
- MobileNetV2
- DeepLabV3Plus
- SCRFD face detection
- OSNet re-identification

---

## 🚀 How to Run Inference

### 1. Load Drivers (after reboot)
```bash
/sbin/insmod /tmp/dx_dma.ko
/sbin/insmod /tmp/dxrt_driver.ko
```

### 2. Start DeepX Service
```bash
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH
nohup /opt/deepx/bin/dxrtd > /var/log/dxrtd.log 2>&1 &
```

### 3. Run Inference
```bash
export PATH=/opt/deepx/bin:/bin:/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH

# Single model test
run_model --model /opt/deepx/models/YoloV8N.dxnn --time 10 --verbose

# Benchmark multiple models
dxbenchmark --dir /opt/deepx/models --time 10 --verbose --sort fps --order desc
```

### 4. Check Device Status
```bash
dxrt-cli -s
```

---

## 📁 File Locations

| Component | Path |
|-----------|------|
| Runtime Binaries | `/opt/deepx/bin/` |
| Libraries | `/opt/deepx/lib/` |
| AI Models | `/opt/deepx/models/` |
| Firmware | `/opt/deepx/firmware/fw-2.5.0.bin` |
| Drivers | `/tmp/dx_dma.ko`, `/tmp/dxrt_driver.ko` |
| Service Log | `/var/log/dxrtd.log` |

---

## 🔄 Update Process Summary

### What Was Done

1. **Cloned Latest DeepX Suite**
   - Repository: https://github.com/DEEPX-AI/dx-all-suite
   - Includes dx-runtime v3.2.0 source
   - Firmware v2.5.0 included

2. **Cross-Compiled Drivers**
   - Built for kernel 5.10.145-cip17-yocto-standard
   - Used Docker with Ubuntu 22.04 + aarch64-linux-gnu toolchain
   - Successfully loaded on board

3. **Updated Firmware**
   - Extracted firmware v2.5.0 from dx-all-suite
   - Updated using: `dxrt-cli -u /tmp/fw-2.5.0.bin`
   - Rebooted board to apply changes

4. **Verified & Tested**
   - Confirmed firmware v2.5.0 active
   - Ran YOLOv8N inference successfully
   - Achieved 54.72 FPS

---

## 🛠️ Build Artifacts Created

### On Host PC
```
compiled_drivers/
├── dx_dma.ko (132.82 KB)
└── dxrt_driver.ko (88.33 KB)

dxrt-latest-arm64/
├── bin/ (28 binaries, 86MB total)
├── lib/ (libdxrt.so, 43MB)
└── firmware/ (fw-2.5.0.bin, 636KB)

dx-all-suite-latest/
└── (Full source code from GitHub)
```

### Build Scripts
- `build_drivers.ps1` - Cross-compile drivers
- `build_latest_runtime.ps1` - Build runtime from source
- `Dockerfile.deepx` - Driver build environment
- `Dockerfile.dxrt-builder` - Runtime build environment

---

## ⚡ Performance Expectations

Based on YOLOv8N test results:

| Model Type | Expected FPS | NPU Time | Notes |
|------------|--------------|----------|-------|
| YOLOv8N | ~55 FPS | ~9.6ms | Lightweight detection |
| YOLOv5S | ~40-50 FPS | ~12-15ms | Standard detection |
| YOLOv7 | ~20-30 FPS | ~25-35ms | Heavy detection |
| EfficientNet | ~100+ FPS | ~5-8ms | Classification |
| MobileNetV2 | ~150+ FPS | ~3-5ms | Lightweight classification |

*Actual performance varies by model complexity and input size*

---

## 🔧 Troubleshooting

### After Reboot

The board loses drivers and models after reboot. To restore:

```bash
# 1. Re-transfer drivers (from host PC)
scp compiled_drivers/*.ko root@192.168.0.165:/tmp/

# 2. Load drivers
ssh root@192.168.0.165 "/sbin/insmod /tmp/dx_dma.ko && /sbin/insmod /tmp/dxrt_driver.ko"

# 3. Re-transfer models if needed
scp models.tar.gz root@192.168.0.165:/tmp/
ssh root@192.168.0.165 "tar xzf /tmp/models.tar.gz -C /opt/deepx/models/"

# 4. Start dxrtd service
ssh root@192.168.0.165 "export LD_LIBRARY_PATH=/opt/deepx/lib:\$LD_LIBRARY_PATH && nohup /opt/deepx/bin/dxrtd > /var/log/dxrtd.log 2>&1 &"
```

### Auto-Load on Boot (Recommended)

To make drivers load automatically:

```bash
# Copy drivers to kernel modules
cp /tmp/dx_dma.ko /lib/modules/5.10.145-cip17-yocto-standard/extra/
cp /tmp/dxrt_driver.ko /lib/modules/5.10.145-cip17-yocto-standard/extra/

# Update module dependencies
depmod -a

# Create startup script
cat > /etc/init.d/deepx-start << 'EOF'
#!/bin/sh
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH
/opt/deepx/bin/dxrtd > /var/log/dxrtd.log 2>&1 &
EOF

chmod +x /etc/init.d/deepx-start
```

---

## 📈 Next Steps

### Recommended Actions

1. **Test All Models**
   ```bash
   dxbenchmark --dir /opt/deepx/models --time 10 --recursive --sort fps --order desc
   ```

2. **Integrate with Your Application**
   - Use C++ API: `/opt/deepx/bin/run_model` examples
   - Python bindings available in dx-all-suite

3. **Optimize Performance**
   - Test different NPU binding options (`--npu 0-6`)
   - Experiment with batch sizes
   - Profile with `dxtop` for real-time monitoring

4. **Production Deployment**
   - Set up auto-start scripts
   - Configure persistent storage for models
   - Implement error handling and recovery

---

## 📚 Resources

- **GitHub Repository:** https://github.com/dvirchakim/iMDT-DEEPX-AI-SBC
- **DeepX Suite:** https://github.com/DEEPX-AI/dx-all-suite
- **Documentation:** Created in this project
  - `BOARD-STATUS-REPORT.md` - Initial examination
  - `RUN-DXBENCHMARK.md` - Benchmark guide
  - `DEEPX-UPDATE-SUCCESS.md` - This file

---

## ✅ Verification Checklist

- [x] PCIe device detected (01:00.0)
- [x] Drivers compiled and loaded
- [x] Firmware updated to v2.5.0
- [x] dxrt-cli shows device status
- [x] dxrtd service running
- [x] Models transferred (25 models)
- [x] Inference test successful (YOLOv8N @ 54.72 FPS)
- [x] All 3 NPUs operational
- [x] Temperature normal (~48-49°C)

---

## 🎉 Summary

**Your iMDT V2H board is now fully operational for AI inference!**

- Firmware: v2.1.0 → v2.5.0 ✅
- First inference: YOLOv8N @ 54.72 FPS ✅
- 25 AI models ready to use ✅
- All 3 NPUs working perfectly ✅

You can now run AI inference workloads on your DeepX M1 accelerator!
