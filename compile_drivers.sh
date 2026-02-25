#!/bin/bash
set -e

echo "=== Cross-compiling DeepX drivers for ARM64 ==="
cd /driver/modules

echo "Building drivers..."
make DEVICE=m1 PCIE=deepx \
    ARCH=arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    KERNEL_DIR=/kernel \
    -j4

echo "Copying compiled drivers..."
mkdir -p /output
cp -v pci_deepx/dx_dma.ko /output/
cp -v rt/dxrt_driver.ko /output/

echo "Build complete!"
ls -lh /output/
