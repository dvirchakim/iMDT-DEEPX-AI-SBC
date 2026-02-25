# DeepX AI Auto-Start Configuration

**Status:** ✅ **CONFIGURED AND WORKING**

---

## What Auto-Starts on Boot

### ✅ Kernel Drivers (Automatic)
```
dx_dma.ko          - DeepX DMA driver
dxrt_driver.ko     - DeepX runtime driver
```

**Location:** `/lib/modules/5.10.145-cip17-yocto-standard/extra/`

These drivers load automatically on boot via the kernel module system.

### ✅ DeepX Service (via rc.local)
```
dxrtd - DeepX runtime daemon
```

**Started by:** `/etc/rc.local`

---

## Configuration Files

### 1. Kernel Modules
**File:** `/lib/modules/5.10.145-cip17-yocto-standard/extra/`
- `dx_dma.ko` (133 KB)
- `dxrt_driver.ko` (88 KB)

### 2. Init Script
**File:** `/etc/init.d/deepx-ai`
- Loads kernel modules (if not already loaded)
- Starts dxrtd service
- Manages PID file at `/var/run/dxrtd.pid`
- Logs to `/var/log/dxrtd.log`

### 3. Auto-Start Script
**File:** `/etc/rc.local`
```bash
#!/bin/sh
/etc/init.d/deepx-ai start
exit 0
```

### 4. Environment Variables
**File:** `/etc/profile.d/deepx.sh`
```bash
export PATH="/opt/deepx/bin:${PATH}"
export LD_LIBRARY_PATH="/opt/deepx/lib:${LD_LIBRARY_PATH}"
```

---

## Service Management

### Start Service
```bash
/etc/init.d/deepx-ai start
```

### Stop Service
```bash
/etc/init.d/deepx-ai stop
```

### Restart Service
```bash
/etc/init.d/deepx-ai restart
```

### Check Status
```bash
/etc/init.d/deepx-ai status
```

---

## Verification After Boot

### 1. Check Drivers Loaded
```bash
lsmod | grep dx
```

**Expected output:**
```
dxrt_driver    45056  0
dx_dma        450560  1 dxrt_driver
```

### 2. Check Service Running
```bash
/etc/init.d/deepx-ai status
```

**Expected output:**
```
DeepX AI service is running (PID: XXX)
```

### 3. Check Device Status
```bash
dxrt-cli -s
```

**Expected output:**
```
DXRT v3.1.0
=======================================================
 * Device 0: M1, Accelerator type
 * FW version: v2.5.0
 * 3 NPUs operational
=======================================================
```

### 4. Test Inference
```bash
run_model --model /opt/deepx/models/YoloV8N.dxnn --time 5 --verbose
```

---

## Boot Sequence

1. **Kernel boots** → Loads drivers from `/lib/modules/.../extra/`
2. **Init system runs** → Executes `/etc/rc.local`
3. **rc.local runs** → Calls `/etc/init.d/deepx-ai start`
4. **Init script runs** → Loads modules (if needed) + starts dxrtd
5. **System ready** → DeepX AI fully operational

---

## Troubleshooting

### Service Not Running After Boot

**Check rc.local:**
```bash
cat /etc/rc.local
ls -la /etc/rc.local
```

**Manually start:**
```bash
/etc/init.d/deepx-ai start
```

### Drivers Not Loaded

**Check module files exist:**
```bash
ls -la /lib/modules/5.10.145-cip17-yocto-standard/extra/dx*.ko
```

**Manually load:**
```bash
/sbin/insmod /lib/modules/5.10.145-cip17-yocto-standard/extra/dx_dma.ko
/sbin/insmod /lib/modules/5.10.145-cip17-yocto-standard/extra/dxrt_driver.ko
```

### Check Logs

**Service log:**
```bash
cat /var/log/dxrtd.log
```

**System log:**
```bash
dmesg | grep -i dx
```

---

## Manual Recovery (If Needed)

If auto-start fails after reboot, run these commands:

```bash
# 1. Load drivers
/sbin/insmod /lib/modules/5.10.145-cip17-yocto-standard/extra/dx_dma.ko
/sbin/insmod /lib/modules/5.10.145-cip17-yocto-standard/extra/dxrt_driver.ko

# 2. Start service
/etc/init.d/deepx-ai start

# 3. Verify
dxrt-cli -s
```

---

## Files Installed

```
/lib/modules/5.10.145-cip17-yocto-standard/extra/
├── dx_dma.ko
└── dxrt_driver.ko

/etc/
├── init.d/
│   └── deepx-ai
├── rc.local
└── profile.d/
    └── deepx.sh

/opt/deepx/
├── bin/
│   ├── dxrtd
│   ├── dxrt-cli
│   ├── dxbenchmark
│   └── run_model (+ 24 other binaries)
├── lib/
│   └── libdxrt.so
├── models/
│   └── (25 .dxnn model files)
└── firmware/
    └── fw-2.5.0.bin

/var/
├── run/
│   └── dxrtd.pid
└── log/
    └── dxrtd.log
```

---

## Summary

✅ **Drivers:** Auto-load on boot  
✅ **Service:** Auto-start via rc.local  
✅ **Environment:** Auto-configured for all users  
✅ **Tested:** Verified after reboot  

**Your DeepX AI system is now fully configured to start automatically on every boot!**

---

## Quick Reference

| Task | Command |
|------|---------|
| Check drivers | `lsmod \| grep dx` |
| Check service | `/etc/init.d/deepx-ai status` |
| Check device | `dxrt-cli -s` |
| Start service | `/etc/init.d/deepx-ai start` |
| Stop service | `/etc/init.d/deepx-ai stop` |
| Restart service | `/etc/init.d/deepx-ai restart` |
| View logs | `cat /var/log/dxrtd.log` |
| Run inference | `run_model --model <path> --time 10` |
