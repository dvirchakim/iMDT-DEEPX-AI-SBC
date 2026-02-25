# CVEDIA RT Installation Guide for iMDT V2H SBC

This guide documents the complete installation process for CVEDIA RT on the iMDT V2H SBC (Yocto Linux, ARM64).

## Prerequisites

- iMDT V2H SBC board with network access
- SSH access to the board (root@10.11.12.79)
- At least 4GB free storage space

## Installation Steps

### 1. Create Storage Partition

The board's root filesystem has limited space. Create a new partition on the SD card for CVEDIA RT:

```bash
# Check current partitions (SD card is ~30GB, only ~5GB used)
cat /proc/partitions | grep mmcblk0

# Create new partition (partition 4, ~24GB)
echo -e 'p\nn\np\n4\n\n\nw' | /sbin/fdisk /dev/mmcblk0

# Reload partition table
partprobe /dev/mmcblk0

# Format the new partition
/sbin/mkfs.ext4 -F /dev/mmcblk0p4

# Create mount point and mount
mkdir -p /opt/cvedia-rt
mount /dev/mmcblk0p4 /opt/cvedia-rt
```

### 2. Add to fstab for Auto-Mount

```bash
echo '/dev/mmcblk0p4 /opt/cvedia-rt ext4 defaults 0 2' >> /etc/fstab
```

### 3. Download CVEDIA RT

Download the legacy ARM64 package (compatible with glibc 2.27+):

```bash
cd /tmp
wget 'http://apt.cvedia.com/pool/legacy/c/cvedia-rt/cvedia-rt_2025.1.1_arm64.deb' -O cvedia-rt.deb
```

**Note**: The download is ~1.1GB and may take 10-15 minutes.

### 4. Extract CVEDIA RT

```bash
# Extract the deb package
cd /tmp
ar x cvedia-rt.deb

# Extract to the CVEDIA partition
cd /opt/cvedia-rt
tar xf /tmp/data.tar.xz

# Move files to root of partition
mv opt/cvedia-rt/* .
rm -rf opt usr

# Verify installation
ls -la /opt/cvedia-rt/rtservice
```

### 5. Install Init Script

Copy the `cvedia-rt-init.sh` script to the board:

```bash
# On the board, create /etc/init.d/cvedia-rt with the content from cvedia-rt-init.sh
chmod +x /etc/init.d/cvedia-rt

# Create symlinks for auto-start
ln -sf /etc/init.d/cvedia-rt /etc/rc3.d/S99cvedia-rt
ln -sf /etc/init.d/cvedia-rt /etc/rc5.d/S99cvedia-rt
```

### 6. Start CVEDIA RT

```bash
/etc/init.d/cvedia-rt start
```

### 7. Verify Installation

```bash
# Check status
/etc/init.d/cvedia-rt status

# Check port is listening
netstat -tln | grep 8090

# View logs
cat /var/log/cvedia-rt.log
```

## Configuration

### Port Configuration

CVEDIA RT runs on port **8090** (not 8080, which is used by V2H Software Update).

To change the port, edit `/etc/init.d/cvedia-rt` and modify the `--webserver-port` parameter.

### Web Panel Access

Open in browser: `http://<board-ip>:8090`

Example: http://10.11.12.79:8090

## Service Management

```bash
# Start
/etc/init.d/cvedia-rt start

# Stop
/etc/init.d/cvedia-rt stop

# Restart
/etc/init.d/cvedia-rt restart

# Status
/etc/init.d/cvedia-rt status
```

## Directory Structure

```
/opt/cvedia-rt/
├── rtservice          # Main service binary
├── rtcmd              # Command-line tool
├── rtstudio           # Studio binary (requires GUI)
├── lib/               # Shared libraries
├── Plugins/           # Plugin modules
├── solutions/         # AI solution templates
│   ├── basic-detection-demo/
│   ├── securt/
│   ├── smart-home/
│   └── drone-detection/
├── assets/            # Model assets
└── www/               # Web panel files
```

## Troubleshooting

### Service won't start

1. Check if partition is mounted:
   ```bash
   mountpoint -q /opt/cvedia-rt && echo "Mounted" || echo "Not mounted"
   ```

2. Check logs:
   ```bash
   cat /var/log/cvedia-rt.log
   ```

3. Check library path:
   ```bash
   export LD_LIBRARY_PATH=/opt/cvedia-rt/lib:/opt/cvedia-rt:$LD_LIBRARY_PATH
   cd /opt/cvedia-rt && ./rtservice --help
   ```

### Port already in use

If port 8090 is in use, change to another port in the init script:
```bash
--webserver-port 8091
```

### Missing libraries

Some plugins may fail to load due to missing system libraries (libva, libhailort). This is expected on Yocto - the core MNN inference engine still works.

## Notes

- **License**: CVEDIA RT requires a license for full functionality. Without a license, you'll see "No license files are found" warnings.
- **Persistence**: The installation is on `/dev/mmcblk0p4` which persists across reboots.
- **RAM Usage**: CVEDIA RT uses approximately 60-70MB RAM when idle.
- **Inference**: MNN inference engine is available for CPU-based inference on ARM64.

## Version Information

- **CVEDIA RT Version**: 2025.1.1 (legacy ARM64)
- **Board**: iMDT V2H SBC
- **OS**: Poky (Yocto) 3.1.33
- **Architecture**: aarch64
- **glibc**: 2.28
