# iMDT V2H DeepX AI SBC - Complete Setup Guide

<img width="1826" height="830" alt="iMDT V2H Board" src="https://github.com/user-attachments/assets/1ab5e1de-3bcb-4bce-b066-026563f04bc9" />

## 🎯 Overview

This repository contains everything needed to deploy **DeepX AI** on the **iMDT V2H SBC** with the DeepX M1 AI accelerator. Includes complete deployment package, firmware updates, drivers, models, and comprehensive documentation.

### Key Features

✅ **Complete Deployment Package** - 828 MB ready-to-deploy ZIP  
✅ **Firmware v2.5.0** - Auto-update from v2.1.0  
✅ **Auto-Start Configuration** - Drivers + service start on boot  
✅ **25 AI Models** - YOLO, EfficientNet, MobileNet, and more  
✅ **Production Ready** - Tested at 54+ FPS on YOLOv8N  
✅ **Comprehensive Docs** - 6 detailed guides included  

---

## ⚡ Quick Start (5 Minutes)

### Prerequisites
- iMDT V2H board with DeepX M1 accelerator
- Network connectivity and SSH access
- ~2 GB free storage

### Installation

**1. Download the deployment package**
```bash
# Clone this repository
git clone https://github.com/dvirchakim/iMDT-DEEPX-AI-SBC.git
cd iMDT-DEEPX-AI-SBC
```

**2. Transfer to your board**
```bash
# Replace <BOARD_IP> with your board's IP address
scp -r deployment root@<BOARD_IP>:/tmp/
```

**3. Install (one command)**
```bash
# SSH into board
ssh root@<BOARD_IP>

# Run installer
cd /tmp/deployment/scripts
chmod +x install.sh
./install.sh
```

**4. Reboot**
```bash
/sbin/reboot
```

**5. Verify (after ~60 seconds)**
```bash
ssh root@<BOARD_IP>
dxrt-cli -s
cd /tmp/deployment/scripts
./test-inference.sh
```

**Done!** Your board is ready for AI inference with auto-start on every boot.

---

## 📦 What's Included

### Deployment Package (`deployment/`)

```
deployment/
├── README.md                    # Complete installation guide
├── QUICK-START.md              # 5-minute quick start
├── VERSION.txt                 # Package information
├── drivers/
│   ├── dx_dma.ko               # DeepX DMA driver (133 KB)
│   └── dxrt_driver.ko          # DeepX runtime driver (88 KB)
├── runtime/
│   └── dxrt-arm64-bin.tar.gz   # DeepX runtime v3.1.0 (55 MB)
├── firmware/
│   └── fw-2.5.0.bin            # Firmware v2.5.0 (636 KB)
├── models/
│   └── models.tar.gz           # 25 AI models (776 MB)
├── scripts/
│   ├── install.sh              # Automated installer
│   ├── deepx-ai-init           # Service init script
│   └── test-inference.sh       # Inference test script
└── docs/
    └── (Complete documentation)
```

### Documentation

- **[DEPLOYMENT-PACKAGE-INFO.md](DEPLOYMENT-PACKAGE-INFO.md)** - Complete package details
- **[QUICK-START.md](deployment/QUICK-START.md)** - 5-minute installation
- **[AUTO-START-GUIDE.md](AUTO-START-GUIDE.md)** - Auto-start configuration
- **[BOARD-STATUS-REPORT.md](BOARD-STATUS-REPORT.md)** - Hardware verification
- **[DEEPX-UPDATE-SUCCESS.md](DEEPX-UPDATE-SUCCESS.md)** - Firmware update process
- **[FINAL-SETUP-SUMMARY.md](FINAL-SETUP-SUMMARY.md)** - Complete system summary
- **[RUN-DXBENCHMARK.md](RUN-DXBENCHMARK.md)** - Benchmark usage guide

### Build Tools

- **Docker Environments** - `Dockerfile.deepx`, `Dockerfile.dxrt-builder`
- **Build Scripts** - `build_drivers.ps1`, `build_latest_runtime.ps1`
- **Pre-compiled Drivers** - `compiled_drivers/` (for kernel 5.10.145)

---

## 🚀 Performance

After installation, expected performance:

| Model | FPS | NPU Time | Use Case |
|-------|-----|----------|----------|
| YOLOv8N | ~55 FPS | ~9.6ms | Object detection |
| YOLOv5S | ~45 FPS | ~13ms | Object detection |
| EfficientNet B0 | ~100 FPS | ~6ms | Classification |
| MobileNetV2 | ~150 FPS | ~4ms | Classification |

**Hardware:**
- 3x NPUs @ 1000 MHz
- 3.92 GiB LPDDR5 memory
- PCIe Gen3 X4 connection
- Temperature: ~47-50°C

---

## 🎯 What Gets Installed

### Software Stack
- **DeepX Runtime:** v3.1.0
- **Firmware:** v2.5.0 (auto-updated from v2.1.0)
- **Drivers:** RT v1.8.0, PCIe v1.6.0
- **Kernel:** 5.10.145-cip17-yocto-standard (aarch64)

### AI Models (25 Total)

**Object Detection:**
- YOLOv3, YOLOv4, YOLOv5 (S, X, variants)
- YOLOv7, YOLOv8N, YOLOv9S
- YOLOX-S

**Specialized:**
- YOLOv5 Pose Detection
- YOLOv5 Face Detection
- SCRFD Face Detection

**Classification:**
- EfficientNet B0
- MobileNetV2

**Segmentation:**
- DeepLabV3Plus + MobileNetV2

**Re-identification:**
- OSNet (Person Re-ID)

### Auto-Start Configuration

✅ **Drivers** - Auto-load from `/lib/modules/.../extra/`  
✅ **Service** - Auto-start via `/etc/rc.local`  
✅ **Environment** - Configured for all users  

---

## 🛠️ Usage

### Check System Status
```bash
# Check device status
dxrt-cli -s

# Check service
/etc/init.d/deepx-ai status

# Check drivers
lsmod | grep dx
```

### Run Inference
```bash
# Single model test
run_model --model /opt/deepx/models/YoloV8N.dxnn --time 10 --verbose

# Benchmark all models
dxbenchmark --dir /opt/deepx/models --time 10 --verbose --sort fps --order desc
```

### Service Management
```bash
# Start service
/etc/init.d/deepx-ai start

# Stop service
/etc/init.d/deepx-ai stop

# Restart service
/etc/init.d/deepx-ai restart

# Check status
/etc/init.d/deepx-ai status
```

---

## 🔧 Building from Source

### Cross-Compile Drivers

```powershell
# On Windows with Docker
.\build_drivers.ps1
```

This will:
1. Build Docker image with ARM64 cross-compiler
2. Compile drivers for kernel 5.10.145-cip17-yocto-standard
3. Output to `compiled_drivers/`

### Build Latest Runtime

```powershell
# Build from dx-all-suite GitHub
.\build_latest_runtime.ps1
```

---

## 📋 System Requirements

### Target Board
- **Model:** iMDT V2H SBC
- **Accelerator:** DeepX M1 M.2 module
- **Kernel:** 5.10.145-cip17-yocto-standard
- **Architecture:** aarch64 (ARM64)
- **Storage:** 2+ GB free space

### Development Environment
- Docker (for cross-compilation)
- PowerShell (for build scripts)
- Git

---

## 🐛 Troubleshooting

### Drivers Don't Load
```bash
# Check kernel version
uname -r
# Must be: 5.10.145-cip17-yocto-standard

# Manually load
/sbin/insmod /lib/modules/5.10.145-cip17-yocto-standard/extra/dx_dma.ko
/sbin/insmod /lib/modules/5.10.145-cip17-yocto-standard/extra/dxrt_driver.ko
```

### Service Won't Start
```bash
# Check logs
cat /var/log/dxrtd.log

# Verify drivers loaded
lsmod | grep dx
```

### Firmware Update Fails
```bash
# Ensure device detected
lspci | grep 1ff4

# Ensure drivers loaded first
lsmod | grep dx
```

See [DEPLOYMENT-PACKAGE-INFO.md](DEPLOYMENT-PACKAGE-INFO.md) for complete troubleshooting guide.

---

## 📚 Additional Resources

### CVEDIA RT Support

This repository also includes CVEDIA RT runtime support. See:
- **[README-CVEDIA.md](README-CVEDIA.md)** - CVEDIA RT overview
- **[INSTALL-CVEDIA-RT.md](INSTALL-CVEDIA-RT.md)** - CVEDIA RT installation

**CVEDIA RT Features:**
- Web Panel on port 8080
- Multiple AI solutions (detection, surveillance, smart-home)
- Auto-start on boot
- Dedicated partition: `/dev/mmcblk0p4`

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

---

## 📝 License

See LICENSE file for details.

---

## 🎉 Success Criteria

Installation is successful when:
- ✅ `lsmod | grep dx` shows both drivers
- ✅ `dxrt-cli -s` shows firmware v2.5.0
- ✅ All 3 NPUs operational
- ✅ Test inference runs at expected FPS (50+ FPS)
- ✅ Service auto-starts after reboot

---

## 📞 Support

For issues or questions:
1. Check the documentation in `docs/` folder
2. Review [DEPLOYMENT-PACKAGE-INFO.md](DEPLOYMENT-PACKAGE-INFO.md)
3. Check logs: `/var/log/dxrtd.log`
4. Verify hardware: `lspci | grep 1ff4`

---

**Your iMDT V2H board is ready for AI inference! 🚀**
