# 📦 DeepX AI Deployment Package

**File:** `iMDT-DeepX-AI-Deployment-v1.0.zip`  
**Version:** 1.0  
**Date:** February 25, 2026  
**Size:** ~832 MB

---

## 🎯 What's Inside

This is a **complete, ready-to-deploy package** for setting up DeepX AI on iMDT V2H boards.

### Package Structure

```
iMDT-DeepX-AI-Deployment-v1.0.zip
├── README.md                    # Complete installation guide
├── QUICK-START.md              # 5-minute quick start
├── VERSION.txt                 # Package version info
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
    ├── AUTO-START-GUIDE.md
    ├── BOARD-STATUS-REPORT.md
    ├── DEEPX-UPDATE-SUCCESS.md
    └── FINAL-SETUP-SUMMARY.md
```

---

## ⚡ Quick Deployment (5 Minutes)

### For the Person Receiving This Package:

**1. Extract the ZIP file**
```bash
unzip iMDT-DeepX-AI-Deployment-v1.0.zip
```

**2. Transfer to your board**
```bash
# Replace <BOARD_IP> with your board's IP (e.g., 192.168.0.165)
scp -r deployment root@<BOARD_IP>:/tmp/
```

**3. SSH into board and install**
```bash
ssh root@<BOARD_IP>
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

**Done!** The system will auto-start on every boot.

---

## 📋 What Gets Installed

### Hardware Support
- **Board:** iMDT V2H SBC
- **Accelerator:** DeepX M1 (M.2 module)
- **NPUs:** 3x @ 1000 MHz
- **Memory:** 3.92 GiB LPDDR5

### Software Components
- **Runtime:** DeepX RT v3.1.0
- **Firmware:** v2.5.0 (upgraded from v2.1.0)
- **Drivers:** RT v1.8.0, PCIe v1.6.0
- **Models:** 25 AI models in .dxnn format
- **Auto-start:** Fully configured

### AI Models Included (25 Total)

**Object Detection:**
- YOLOv3, YOLOv4, YOLOv5 (S, X, variants)
- YOLOv7, YOLOv8N, YOLOv9S
- YOLOX-S

**Specialized:**
- YOLOv5 Pose, Face Detection
- SCRFD Face Detection

**Classification:**
- EfficientNet B0
- MobileNetV2

**Segmentation:**
- DeepLabV3Plus

**Re-ID:**
- OSNet

---

## 🚀 Expected Performance

After installation:

| Model | FPS | NPU Time | Use Case |
|-------|-----|----------|----------|
| YOLOv8N | ~55 FPS | ~9.6ms | Object detection |
| YOLOv5S | ~45 FPS | ~13ms | Object detection |
| EfficientNet | ~100 FPS | ~6ms | Classification |
| MobileNetV2 | ~150 FPS | ~4ms | Classification |

---

## 📝 System Requirements

### Target Board
- **Model:** iMDT V2H SBC
- **Accelerator:** DeepX M1 M.2 module
- **Kernel:** 5.10.145-cip17-yocto-standard
- **Architecture:** aarch64 (ARM64)
- **Storage:** 2+ GB free space
- **Network:** SSH access required

### Installation Requirements
- Root access to board
- Network connectivity
- ~5 minutes installation time
- One reboot required

---

## 🎯 Features

### ✅ Fully Automated
- One-command installation
- Auto-detects and configures everything
- Verifies installation at each step

### ✅ Auto-Start on Boot
- Drivers load automatically
- Service starts automatically
- No manual intervention needed

### ✅ Production Ready
- Tested and verified
- Complete documentation
- Troubleshooting guides included

### ✅ Easy to Share
- Single ZIP file
- Complete package
- No dependencies to download
- Works offline after transfer

---

## 📚 Documentation Included

1. **README.md** - Complete installation guide with troubleshooting
2. **QUICK-START.md** - 5-minute quick start guide
3. **AUTO-START-GUIDE.md** - Auto-start configuration details
4. **BOARD-STATUS-REPORT.md** - Hardware verification info
5. **DEEPX-UPDATE-SUCCESS.md** - Firmware update process
6. **FINAL-SETUP-SUMMARY.md** - Complete system summary

---

## 🔧 Troubleshooting

All common issues and solutions are documented in `README.md`.

Quick fixes:
- **Drivers won't load:** Check kernel version matches
- **Service won't start:** Check logs at `/var/log/dxrtd.log`
- **Models missing:** Re-extract from `models.tar.gz`
- **Firmware update fails:** Ensure drivers loaded first

---

## 📞 Support

For issues:
1. Check `README.md` in the package
2. Review logs: `/var/log/dxrtd.log`
3. Verify hardware: `lspci | grep 1ff4`
4. Check documentation in `docs/` folder

---

## ✅ Verification Checklist

After installation, verify:
- [ ] `lsmod | grep dx` shows both drivers
- [ ] `dxrt-cli -s` shows firmware v2.5.0
- [ ] All 3 NPUs operational
- [ ] Test inference runs at expected FPS
- [ ] Service auto-starts after reboot

---

## 🎉 Success Criteria

Installation successful when:
- ✅ Drivers auto-load on boot
- ✅ Service auto-starts on boot
- ✅ Device shows firmware v2.5.0
- ✅ All 3 NPUs operational
- ✅ Test inference achieves 50+ FPS

---

## 📦 Sharing This Package

### To Send to Others:

**Option 1: Direct Transfer**
```bash
# Via SCP
scp iMDT-DeepX-AI-Deployment-v1.0.zip user@remote-host:/path/

# Via USB
# Copy to USB drive and physically transfer
```

**Option 2: Cloud Storage**
- Upload to Google Drive, Dropbox, etc.
- Share download link
- Recipient downloads and extracts

**Option 3: Network Share**
- Place on shared network drive
- Others can copy directly

### Instructions for Recipients:

1. Download/receive the ZIP file
2. Extract it
3. Follow `QUICK-START.md`
4. Installation takes ~5 minutes
5. System ready after reboot

---

## 🔄 Updates

To update this package in the future:
1. Replace files in respective folders
2. Update `VERSION.txt`
3. Re-create ZIP file
4. Distribute new version

---

## 📊 Package Statistics

- **Total Size:** ~832 MB
- **Files:** 20+ files
- **Models:** 25 AI models
- **Documentation:** 6 guides
- **Scripts:** 3 automated scripts
- **Installation Time:** ~5 minutes
- **Reboot Required:** Yes (once)

---

## 🌟 What Makes This Package Special

✅ **Complete** - Everything needed in one file  
✅ **Automated** - One-command installation  
✅ **Tested** - Verified on actual hardware  
✅ **Documented** - Comprehensive guides included  
✅ **Production Ready** - Auto-start configured  
✅ **Easy to Share** - Single ZIP file  
✅ **Offline Capable** - No internet needed on target  

---

**This package is ready to deploy on any iMDT V2H board with DeepX M1 accelerator!**

Just extract, transfer, run `install.sh`, and reboot. That's it! 🚀
