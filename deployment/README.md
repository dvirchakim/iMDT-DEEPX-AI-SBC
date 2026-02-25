# iMDT V2H DeepX AI Deployment Package

**Version:** 1.0  
**Date:** February 25, 2026  
**Board:** iMDT V2H SBC with DeepX M1 AI Accelerator

---

## 📦 Package Contents

This deployment package contains everything needed to set up DeepX AI on your iMDT V2H board.

```
deployment/
├── README.md                    # This file
├── QUICK-START.md              # Quick installation guide
├── drivers/
│   ├── dx_dma.ko               # DeepX DMA driver (133 KB)
│   └── dxrt_driver.ko          # DeepX runtime driver (88 KB)
├── runtime/
│   └── dxrt-arm64-bin.tar.gz   # DeepX runtime binaries (55 MB)
├── firmware/
│   └── fw-2.5.0.bin            # DeepX firmware v2.5.0 (636 KB)
├── models/
│   └── models.tar.gz           # 25 AI models (776 MB)
├── scripts/
│   ├── install.sh              # Main installation script
│   ├── deepx-ai-init           # Service init script
│   └── test-inference.sh       # Test script
└── docs/
    ├── AUTO-START-GUIDE.md
    ├── BOARD-STATUS-REPORT.md
    └── DEEPX-UPDATE-SUCCESS.md
```

---

## ⚡ Quick Installation (5 Minutes)

### Prerequisites
- iMDT V2H board with DeepX M1 accelerator
- Board connected to network
- SSH access to board as root

### Installation Steps

**1. Transfer package to board:**
```bash
# From your PC
scp -r deployment root@<BOARD_IP>:/tmp/
```

**2. Run installation script:**
```bash
# SSH into board
ssh root@<BOARD_IP>

# Run installer
cd /tmp/deployment
chmod +x scripts/install.sh
./scripts/install.sh
```

**3. Reboot board:**
```bash
/sbin/reboot
```

**4. Verify installation:**
```bash
# After reboot (wait ~60 seconds)
ssh root@<BOARD_IP>

# Check status
dxrt-cli -s

# Run test
./scripts/test-inference.sh
```

**Done! Your board is ready for AI inference.**

---

## 📋 What Gets Installed

### Kernel Drivers
- **Location:** `/lib/modules/5.10.145-cip17-yocto-standard/extra/`
- **Files:** `dx_dma.ko`, `dxrt_driver.ko`
- **Auto-loads on boot**

### DeepX Runtime
- **Location:** `/opt/deepx/`
- **Binaries:** 28 executables (dxbenchmark, dxrt-cli, run_model, etc.)
- **Libraries:** libdxrt.so
- **Version:** v3.1.0

### Firmware
- **Version:** v2.5.0
- **Installed to:** Device flash memory
- **Requires:** One-time reboot after update

### AI Models (25 Total)
- **Location:** `/opt/deepx/models/`
- **Format:** .dxnn (DeepX optimized)
- **Types:** YOLO variants, EfficientNet, MobileNet, etc.

### Auto-Start Service
- **Service:** `/etc/init.d/deepx-ai`
- **Auto-start:** `/etc/rc.local`
- **Logs:** `/var/log/dxrtd.log`

---

## 🎯 Expected Performance

After installation, you should see:

| Model | FPS | NPU Time | Use Case |
|-------|-----|----------|----------|
| YOLOv8N | ~55 FPS | ~9.6ms | Object detection |
| YOLOv5S | ~45 FPS | ~13ms | Object detection |
| EfficientNet B0 | ~100 FPS | ~6ms | Classification |
| MobileNetV2 | ~150 FPS | ~4ms | Classification |

---

## 🔧 Manual Installation (If Needed)

If the automated script fails, follow these manual steps:

### 1. Install Drivers
```bash
cd /tmp/deployment/drivers
cp dx_dma.ko /lib/modules/5.10.145-cip17-yocto-standard/extra/
cp dxrt_driver.ko /lib/modules/5.10.145-cip17-yocto-standard/extra/
```

### 2. Install Runtime
```bash
mkdir -p /opt/deepx
tar xzf /tmp/deployment/runtime/dxrt-arm64-bin.tar.gz -C /opt/deepx/
```

### 3. Update Firmware
```bash
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH
/opt/deepx/bin/dxrt-cli -u /tmp/deployment/firmware/fw-2.5.0.bin
```

### 4. Install Models
```bash
tar xzf /tmp/deployment/models/models.tar.gz -C /opt/deepx/models/
```

### 5. Configure Auto-Start
```bash
cp /tmp/deployment/scripts/deepx-ai-init /etc/init.d/deepx-ai
chmod +x /etc/init.d/deepx-ai

cat > /etc/rc.local << 'EOF'
#!/bin/sh
/etc/init.d/deepx-ai start
exit 0
EOF
chmod +x /etc/rc.local
```

### 6. Configure Environment
```bash
cat > /etc/profile.d/deepx.sh << 'EOF'
export PATH="/opt/deepx/bin:${PATH}"
export LD_LIBRARY_PATH="/opt/deepx/lib:${LD_LIBRARY_PATH}"
EOF
chmod +x /etc/profile.d/deepx.sh
```

### 7. Reboot
```bash
/sbin/reboot
```

---

## ✅ Verification

After installation and reboot:

```bash
# 1. Check drivers
lsmod | grep dx
# Expected: dx_dma and dxrt_driver loaded

# 2. Check service
/etc/init.d/deepx-ai status
# Expected: DeepX AI service is running

# 3. Check device
dxrt-cli -s
# Expected: Shows 3 NPUs, firmware v2.5.0

# 4. Run test inference
cd /tmp/deployment/scripts
./test-inference.sh
# Expected: ~55 FPS on YOLOv8N
```

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

# Try manual start
export LD_LIBRARY_PATH=/opt/deepx/lib:$LD_LIBRARY_PATH
/opt/deepx/bin/dxrtd
```

### Firmware Update Fails
```bash
# Check device detected
lspci | grep 1ff4

# Ensure drivers loaded first
lsmod | grep dx
```

### Models Missing
```bash
# Re-extract
tar xzf /tmp/deployment/models/models.tar.gz -C /opt/deepx/models/
```

---

## 📞 Support

For issues or questions:
1. Check the documentation in `docs/` folder
2. Review logs: `/var/log/dxrtd.log`
3. Verify hardware: `lspci | grep 1ff4`

---

## 📝 System Requirements

- **Board:** iMDT V2H SBC
- **Accelerator:** DeepX M1 (M.2 module)
- **Kernel:** 5.10.145-cip17-yocto-standard
- **Architecture:** aarch64 (ARM64)
- **Storage:** ~2 GB free space
- **Network:** SSH access required for installation

---

## 🔄 Updates

To update firmware or runtime in the future:
1. Replace files in `firmware/` or `runtime/` folders
2. Re-run installation script
3. Reboot board

---

## ⚠️ Important Notes

- **Reboot required** after firmware update
- **Drivers must match** kernel version exactly
- **Models are large** (~776 MB) - ensure adequate storage
- **Service auto-starts** on boot after installation
- **Environment variables** configured for all users

---

## 🎉 Success Criteria

Installation is successful when:
- ✅ `lsmod | grep dx` shows both drivers
- ✅ `dxrt-cli -s` shows firmware v2.5.0
- ✅ All 3 NPUs operational
- ✅ Test inference runs at expected FPS
- ✅ Service auto-starts after reboot

---

**Your DeepX AI system should now be fully operational!**
