#!/bin/sh
### BEGIN INIT INFO
# Provides:          cvedia-rt
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       CVEDIA RT Server
### END INIT INFO

CVEDIA_DIR=/opt/cvedia-rt
PIDFILE=/var/run/cvedia-rt.pid
LOGFILE=/var/log/cvedia-rt.log

mount_partition() {
    if ! mountpoint -q /opt/cvedia-rt; then
        mkdir -p /opt/cvedia-rt
        mount /dev/mmcblk0p4 /opt/cvedia-rt
        sleep 2
    fi
}

is_running() {
    pgrep -f "rtservice" > /dev/null 2>&1
}

get_pid() {
    pgrep -f "rtservice" 2>/dev/null | head -1
}

case "$1" in
    start)
        echo "Starting CVEDIA RT..."
        mount_partition
        if is_running; then
            echo "CVEDIA RT already running (PID: $(get_pid))"
            exit 0
        fi
        cd $CVEDIA_DIR
        export LD_LIBRARY_PATH=$CVEDIA_DIR/lib:$CVEDIA_DIR:$LD_LIBRARY_PATH
        nohup ./rtservice --webserver --webserver-host 0.0.0.0 --webserver-port 8090 --log-console > $LOGFILE 2>&1 &
        sleep 3
        if is_running; then
            get_pid > $PIDFILE
            echo "CVEDIA RT started (PID: $(get_pid))"
        else
            echo "CVEDIA RT failed to start. Check $LOGFILE"
            exit 1
        fi
        ;;
    stop)
        echo "Stopping CVEDIA RT..."
        pkill -f rtservice 2>/dev/null
        rm -f $PIDFILE
        sleep 2
        if is_running; then
            pkill -9 -f rtservice 2>/dev/null
        fi
        echo "CVEDIA RT stopped"
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    status)
        if is_running; then
            echo "CVEDIA RT is running (PID: $(get_pid))"
        else
            echo "CVEDIA RT is not running"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
exit 0
