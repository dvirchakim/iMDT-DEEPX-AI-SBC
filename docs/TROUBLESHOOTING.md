# Troubleshooting Guide

## Common Issues and Solutions

### 1. PCIe Device Not Detected

**Symptom**: `lspci` doesn't show the DeepX device (vendor ID 1ff4)

**Solutions**:

```bash
# Check if device is visible
lspci | grep -i 1ff4

# If not visible, reset the M.2 slot via GPIO
echo 979 > /sys/class/gpio/export 2>/dev/null
echo out > /sys/class/gpio/gpio979/direction
echo 0 > /sys/class/gpio/gpio979/value
sleep 1
echo 1 > /sys/class/gpio/gpio979/value
sleep 2

# Check again
lspci | grep -i 1ff4
```

**If still not working**:
- Check physical M.2 module seating
- Verify M.2 slot power
- Check for PCIe errors in `dmesg | grep -i pci`

---

### 2. Driver Loading Fails

**Symptom**: `insmod` or `modprobe` fails with errors

**Check kernel version**:
```bash
uname -r
# Expected: 5.10.145-cip17-yocto-standard
```

**Check driver info**:
```bash
modinfo /lib/modules/$(uname -r)/extra/dxrt_driver.ko
```

**View detailed errors**:
```bash
dmesg | tail -50
dmesg | grep -i -E '(dx|deepx|error)'
```

**Common causes**:
- Kernel version mismatch - rebuild drivers for your kernel
- Missing dependencies - ensure `dx_dma.ko` is loaded first
- Device not detected - see PCIe troubleshooting above

---

### 3. glibc Version Mismatch

**Symptom**: 
```
/usr/local/bin/dxrt-cli: /lib64/libc.so.6: version `GLIBC_2.34' not found
```

**Cause**: Binaries were compiled with a newer glibc than the board has.

**Solution**: Rebuild using Ubuntu 18.04 Docker image (glibc 2.27):

```bash
# Check board's glibc version
strings /lib64/libc.so.6 | grep GLIBC | tail -5

# Rebuild with older toolchain
# The provided Dockerfiles use Ubuntu 18.04 for compatibility
```

---

### 4. dxrt-cli Shows No Device

**Symptom**: `dxrt-cli -s` shows no devices or errors

**Check drivers are loaded**:
```bash
lsmod | grep dx
# Should show: dxrt_driver, dx_dma
```

**Check device nodes**:
```bash
ls -la /dev/dx*
# Should show: /dev/dx0, /dev/dx_dma0
```

**Check library path**:
```bash
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ldd /usr/local/bin/dxrt-cli
```

---

### 5. Permission Denied Errors

**Symptom**: Cannot access `/dev/dx0` or run commands

**Solution**:
```bash
# Run as root
sudo dxrt-cli -s

# Or fix permissions
chmod 666 /dev/dx*
```

---

### 6. Build Fails - CMake Version

**Symptom**: 
```
CMake 3.14 or higher is required. You are running version 3.10.2
```

**Solution**: The Dockerfile.runtime installs CMake 3.22. If building manually:

```bash
wget -qO- https://cmake.org/files/v3.22/cmake-3.22.6-linux-x86_64.tar.gz | tar xz -C /opt
export PATH=/opt/cmake-3.22.6-linux-x86_64/bin:$PATH
```

---

### 7. Network/WiFi Connection Issues

**Connect to WiFi**:
```bash
/opt/imdt/wifi/connect-to-access-point.sh "SSID" "PASSWORD"
```

**Check connection**:
```bash
/opt/imdt/wifi/get-connection-status.sh
ip addr show wlan0
```

**Test connectivity**:
```bash
ping -c 3 8.8.8.8
```

---

### 8. Firmware Version Mismatch

**Check firmware**:
```bash
dxrt-cli -s
# Look for "FW version" line
```

**Update firmware** (if needed):
```bash
dxrt-cli -u /path/to/fw.bin
# Reboot after update
```

---

## Diagnostic Commands

```bash
# System info
uname -a
cat /etc/os-release

# PCIe devices
lspci -vvv

# Loaded modules
lsmod | grep dx

# Kernel messages
dmesg | grep -i -E '(dx|deepx|pci|1ff4)'

# Device nodes
ls -la /dev/dx*

# Library dependencies
ldd /usr/local/bin/dxrt-cli

# DeepX status
dxrt-cli -s
dxrt-cli -h
```

---

## Getting Help

1. Check kernel messages: `dmesg | tail -100`
2. Verify hardware connections
3. Ensure correct kernel version
4. Check [DeepX GitHub Issues](https://github.com/DEEPX-AI/dx-all-suite/issues)
