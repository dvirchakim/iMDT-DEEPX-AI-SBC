# Technical Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    iMDT V2H SBC                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 User Applications                    │   │
│  │              (Python, C++, GStreamer)               │   │
│  └─────────────────────┬───────────────────────────────┘   │
│                        │                                    │
│  ┌─────────────────────▼───────────────────────────────┐   │
│  │                   DX-RT Runtime                      │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────────────────┐  │   │
│  │  │dxrt-cli │  │ dxrtd   │  │    libdxrt.so       │  │   │
│  │  │  (CLI)  │  │(daemon) │  │  (Runtime Library)  │  │   │
│  │  └─────────┘  └─────────┘  └─────────────────────┘  │   │
│  └─────────────────────┬───────────────────────────────┘   │
│                        │                                    │
│  ┌─────────────────────▼───────────────────────────────┐   │
│  │              Kernel Drivers                          │   │
│  │  ┌─────────────────┐  ┌─────────────────────────┐   │   │
│  │  │ dxrt_driver.ko  │  │      dx_dma.ko          │   │   │
│  │  │  (NPU Driver)   │  │    (DMA Engine)         │   │   │
│  │  └────────┬────────┘  └───────────┬─────────────┘   │   │
│  └───────────┼───────────────────────┼─────────────────┘   │
│              │                       │                      │
│  ┌───────────▼───────────────────────▼─────────────────┐   │
│  │                    PCIe Bus                          │   │
│  │                  Gen3 x4 Link                        │   │
│  └───────────────────────┬─────────────────────────────┘   │
└──────────────────────────┼──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                   DeepX DX-M1 Module                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  3x NPU Cores                        │   │
│  │              (1000 MHz each)                         │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              LPDDR5 Memory (4GB)                     │   │
│  │                 5600 Mbps                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### Hardware

| Component | Specification |
|-----------|---------------|
| **SBC** | iMDT V2H (Renesas RZ/V2H) |
| **CPU** | ARM Cortex-A76 + Cortex-A55 |
| **AI Accelerator** | DeepX DX-M1 |
| **NPU Cores** | 3x @ 1000 MHz |
| **NPU Memory** | 4GB LPDDR5 |
| **PCIe Interface** | Gen3 x4 |
| **Form Factor** | M.2 Key M |

### Software Stack

#### Kernel Drivers

**dxrt_driver.ko**
- Main NPU driver
- Handles device initialization
- Manages NPU cores
- Creates `/dev/dx0` device node

**dx_dma.ko**
- DMA engine driver
- Handles data transfers between host and NPU memory
- Creates `/dev/dx_dma0` device node

#### Runtime Components

**libdxrt.so**
- Core runtime library
- Model loading and parsing
- Inference execution
- Memory management
- Multi-process support

**dxrtd**
- Runtime daemon
- Service management
- Resource scheduling

**dxrt-cli**
- Command-line interface
- Device status monitoring
- Firmware updates
- Diagnostics

**dxtop**
- Real-time NPU monitoring
- Similar to `htop` for NPUs

## Build System

### Cross-Compilation Requirements

The iMDT V2H SBC runs a Yocto-based Linux without development tools. All software must be cross-compiled on a host PC.

**Target System**:
- Architecture: aarch64 (ARM64)
- Kernel: 5.10.145-cip17-yocto-standard
- glibc: 2.28

**Build Environment**:
- Ubuntu 18.04 Docker (for glibc 2.27 compatibility)
- aarch64-linux-gnu toolchain
- CMake 3.14+

### Build Process

```
Host PC (x86_64)                    Target Board (aarch64)
┌────────────────────┐              ┌────────────────────┐
│                    │              │                    │
│  Docker Container  │   Transfer   │   iMDT V2H SBC     │
│  (Ubuntu 18.04)    │ ──────────►  │                    │
│                    │              │                    │
│  ┌──────────────┐  │              │  ┌──────────────┐  │
│  │Cross-compile │  │              │  │   Install    │  │
│  │   Drivers    │  │              │  │   Drivers    │  │
│  └──────────────┘  │              │  └──────────────┘  │
│                    │              │                    │
│  ┌──────────────┐  │              │  ┌──────────────┐  │
│  │Cross-compile │  │              │  │   Install    │  │
│  │   Runtime    │  │              │  │   Runtime    │  │
│  └──────────────┘  │              │  └──────────────┘  │
│                    │              │                    │
└────────────────────┘              └────────────────────┘
```

## File Locations

### On Board (After Installation)

```
/lib/modules/5.10.145-cip17-yocto-standard/extra/
├── dxrt_driver.ko          # NPU driver
└── dx_dma.ko               # DMA driver

/etc/modules-load.d/
└── deepx.conf              # Auto-load config

/etc/modprobe.d/
└── dx_dma.conf             # DMA parameters

/usr/local/bin/
├── dxrt-cli                # CLI tool
├── dxrtd                   # Daemon
└── dxtop                   # Monitor

/usr/local/lib/
└── libdxrt.so*             # Runtime library

/dev/
├── dx0                     # NPU device
└── dx_dma0                 # DMA device
```

## PCIe Configuration

The DeepX DX-M1 appears as:
- **Vendor ID**: 0x1ff4
- **Device ID**: 0x0000
- **Class**: Processing accelerators

```bash
# View PCIe details
lspci -vvv -d 1ff4:
```

## GPIO Control

The M.2 slot can be reset via GPIO 979:

```bash
# Export GPIO
echo 979 > /sys/class/gpio/export

# Set as output
echo out > /sys/class/gpio/gpio979/direction

# Reset sequence
echo 0 > /sys/class/gpio/gpio979/value  # Power off
sleep 1
echo 1 > /sys/class/gpio/gpio979/value  # Power on
```

## Memory Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Host Memory                          │
│                  (System RAM)                           │
└─────────────────────┬───────────────────────────────────┘
                      │ PCIe DMA
                      ▼
┌─────────────────────────────────────────────────────────┐
│                   NPU Memory                            │
│               (4GB LPDDR5 on M1)                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│  │   Model     │ │   Input     │ │   Output    │       │
│  │   Weights   │ │   Tensors   │ │   Tensors   │       │
│  └─────────────┘ └─────────────┘ └─────────────┘       │
└─────────────────────────────────────────────────────────┘
```

## Version Compatibility

| Component | Version |
|-----------|---------|
| DX-RT | v3.1.0 |
| RT Driver | v1.8.0 |
| PCIe Driver | v1.6.0 |
| Firmware | v2.4.0 |
| Kernel | 5.10.145-cip17 |
