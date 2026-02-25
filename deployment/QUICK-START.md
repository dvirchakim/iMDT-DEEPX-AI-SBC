# Quick Start Guide - 5 Minute Setup

## Step 1: Transfer Package to Board

```bash
# Replace <BOARD_IP> with your board's IP address (e.g., 192.168.0.165)
scp -r deployment root@<BOARD_IP>:/tmp/
```

## Step 2: Install

```bash
# SSH into board
ssh root@<BOARD_IP>

# Run installer
cd /tmp/deployment/scripts
chmod +x install.sh
./install.sh
```

## Step 3: Reboot

```bash
/sbin/reboot
```

Wait ~60 seconds for board to reboot.

## Step 4: Verify

```bash
# SSH back in
ssh root@<BOARD_IP>

# Check status
dxrt-cli -s

# Should show:
# - Firmware v2.5.0
# - 3 NPUs operational
# - All systems ready
```

## Step 5: Test Inference

```bash
cd /tmp/deployment/scripts
./test-inference.sh

# Should show:
# - YOLOv8N running at ~55 FPS
# - NPU processing time ~9.6ms
```

## ✅ Done!

Your board is now ready for AI inference. The system will auto-start on every boot.

### Quick Commands

```bash
# Check service status
/etc/init.d/deepx-ai status

# Check device
dxrt-cli -s

# Run inference
run_model --model /opt/deepx/models/YoloV8N.dxnn --time 10

# Benchmark all models
dxbenchmark --dir /opt/deepx/models --time 10 --verbose
```
