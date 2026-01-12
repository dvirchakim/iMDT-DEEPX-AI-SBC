# CVEDIA RT Support for iMDT V2H SBC

## Overview
This branch adds CVEDIA RT runtime support to the iMDT V2H SBC board.

## Installation

CVEDIA RT 2025.1.1 (legacy ARM64 build) is installed on a dedicated partition:
- **Partition**: `/dev/mmcblk0p4` (24GB)
- **Mount point**: `/opt/cvedia-rt`
- **Web Panel**: http://10.11.12.79:8080

## Auto-start on Boot

The init script `/etc/init.d/cvedia-rt` handles:
1. Mounting the CVEDIA partition
2. Starting the rtservice with web panel enabled
3. Logging to `/var/log/cvedia-rt.log`

### Manual Control
```bash
# Start CVEDIA RT
/etc/init.d/cvedia-rt start

# Stop CVEDIA RT
/etc/init.d/cvedia-rt stop

# Restart CVEDIA RT
/etc/init.d/cvedia-rt restart

# Check status
/etc/init.d/cvedia-rt status
```

## Available Solutions
- basic-detection-demo
- securt (Security/Surveillance)
- smart-home
- drone-detection

## Ports
- **8080**: Web Panel & REST API
- **3546**: Internal API (localhost only)
- **50000**: Auto-discovery broadcast

## Notes
- License required for full functionality
- Some plugins (HLS, HAILO) require additional libraries not available on Yocto
- MNN inference engine is available for CPU-based inference

## Files
- `cvedia-rt-init.sh` - Init script for auto-start
- `smooth_stream_server.py` - DeepX AI streaming server (alternative)
