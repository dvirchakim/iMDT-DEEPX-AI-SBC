#!/bin/sh
# Setup script to configure DeepX AI auto-start on boot
# Run this on the board: ./setup_autostart.sh

set -e

echo "=== DeepX AI Auto-Start Setup ==="
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

KERNEL_VER="5.10.145-cip17-yocto-standard"
MODULE_DIR="/lib/modules/${KERNEL_VER}/extra"
DEEPX_BIN="/opt/deepx/bin"
DEEPX_LIB="/opt/deepx/lib"

echo "Step 1: Installing kernel modules..."
mkdir -p ${MODULE_DIR}

# Copy drivers to kernel modules directory
if [ -f /tmp/dx_dma.ko ]; then
    cp -v /tmp/dx_dma.ko ${MODULE_DIR}/
    echo "  ✓ dx_dma.ko installed"
else
    echo "  ✗ Error: /tmp/dx_dma.ko not found!"
    exit 1
fi

if [ -f /tmp/dxrt_driver.ko ]; then
    cp -v /tmp/dxrt_driver.ko ${MODULE_DIR}/
    echo "  ✓ dxrt_driver.ko installed"
else
    echo "  ✗ Error: /tmp/dxrt_driver.ko not found!"
    exit 1
fi

echo ""
echo "Step 2: Updating module dependencies..."
depmod -a
echo "  ✓ Module dependencies updated"

echo ""
echo "Step 3: Creating module load configuration..."
cat > /etc/modules-load.d/deepx.conf << 'EOF'
# DeepX AI kernel modules
dx_dma
dxrt_driver
EOF
echo "  ✓ Created /etc/modules-load.d/deepx.conf"

echo ""
echo "Step 4: Creating DeepX service init script..."
cat > /etc/init.d/deepx-ai << 'EOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          deepx-ai
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: DeepX AI Runtime Service
# Description:       Starts the DeepX AI runtime daemon (dxrtd)
### END INIT INFO

DEEPX_BIN="/opt/deepx/bin"
DEEPX_LIB="/opt/deepx/lib"
DXRTD="${DEEPX_BIN}/dxrtd"
PIDFILE="/var/run/dxrtd.pid"
LOGFILE="/var/log/dxrtd.log"

export LD_LIBRARY_PATH="${DEEPX_LIB}:${LD_LIBRARY_PATH}"

start() {
    echo "Starting DeepX AI Runtime Service..."
    
    # Check if already running
    if [ -f ${PIDFILE} ]; then
        PID=$(cat ${PIDFILE})
        if kill -0 ${PID} 2>/dev/null; then
            echo "DeepX AI service is already running (PID: ${PID})"
            return 0
        fi
    fi
    
    # Start dxrtd in background
    ${DXRTD} > ${LOGFILE} 2>&1 &
    PID=$!
    echo ${PID} > ${PIDFILE}
    
    # Wait a moment and verify it started
    sleep 2
    if kill -0 ${PID} 2>/dev/null; then
        echo "DeepX AI service started successfully (PID: ${PID})"
        return 0
    else
        echo "Failed to start DeepX AI service"
        rm -f ${PIDFILE}
        return 1
    fi
}

stop() {
    echo "Stopping DeepX AI Runtime Service..."
    
    if [ ! -f ${PIDFILE} ]; then
        echo "DeepX AI service is not running"
        return 0
    fi
    
    PID=$(cat ${PIDFILE})
    if kill -0 ${PID} 2>/dev/null; then
        kill ${PID}
        sleep 2
        
        # Force kill if still running
        if kill -0 ${PID} 2>/dev/null; then
            kill -9 ${PID}
        fi
        
        rm -f ${PIDFILE}
        echo "DeepX AI service stopped"
    else
        echo "DeepX AI service was not running"
        rm -f ${PIDFILE}
    fi
    
    return 0
}

status() {
    if [ -f ${PIDFILE} ]; then
        PID=$(cat ${PIDFILE})
        if kill -0 ${PID} 2>/dev/null; then
            echo "DeepX AI service is running (PID: ${PID})"
            return 0
        else
            echo "DeepX AI service is not running (stale PID file)"
            return 1
        fi
    else
        echo "DeepX AI service is not running"
        return 1
    fi
}

restart() {
    stop
    sleep 1
    start
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit $?
EOF

chmod +x /etc/init.d/deepx-ai
echo "  ✓ Created /etc/init.d/deepx-ai"

echo ""
echo "Step 5: Creating environment setup script..."
cat > /etc/profile.d/deepx.sh << 'EOF'
# DeepX AI environment variables
export PATH="/opt/deepx/bin:${PATH}"
export LD_LIBRARY_PATH="/opt/deepx/lib:${LD_LIBRARY_PATH}"
EOF
chmod +x /etc/profile.d/deepx.sh
echo "  ✓ Created /etc/profile.d/deepx.sh"

echo ""
echo "Step 6: Enabling auto-start..."
# Try to enable with update-rc.d if available
if command -v update-rc.d >/dev/null 2>&1; then
    update-rc.d deepx-ai defaults
    echo "  ✓ Service enabled with update-rc.d"
else
    # Manual symlink creation for systems without update-rc.d
    for runlevel in 2 3 4 5; do
        ln -sf /etc/init.d/deepx-ai /etc/rc${runlevel}.d/S99deepx-ai 2>/dev/null || true
    done
    for runlevel in 0 1 6; do
        ln -sf /etc/init.d/deepx-ai /etc/rc${runlevel}.d/K01deepx-ai 2>/dev/null || true
    done
    echo "  ✓ Service enabled with manual symlinks"
fi

echo ""
echo "Step 7: Starting DeepX service now..."
/etc/init.d/deepx-ai start

echo ""
echo "=== Setup Complete ==="
echo ""
echo "DeepX AI is now configured to auto-start on boot!"
echo ""
echo "Service commands:"
echo "  /etc/init.d/deepx-ai start   - Start the service"
echo "  /etc/init.d/deepx-ai stop    - Stop the service"
echo "  /etc/init.d/deepx-ai restart - Restart the service"
echo "  /etc/init.d/deepx-ai status  - Check service status"
echo ""
echo "Verify setup:"
echo "  lsmod | grep dx              - Check drivers loaded"
echo "  /etc/init.d/deepx-ai status  - Check service status"
echo "  dxrt-cli -s                  - Check device status"
echo ""
echo "To test auto-start, reboot the board:"
echo "  /sbin/reboot"
echo ""
