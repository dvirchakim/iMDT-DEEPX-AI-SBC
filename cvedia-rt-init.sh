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

export LD_LIBRARY_PATH=$CVEDIA_DIR/lib:$CVEDIA_DIR:$LD_LIBRARY_PATH

mount_partition() {
    if ! mountpoint -q /opt/cvedia-rt; then
        mkdir -p /opt/cvedia-rt
        mount /dev/mmcblk0p4 /opt/cvedia-rt
    fi
}

case "$1" in
    start)
        echo "Starting CVEDIA RT..."
        mount_partition
        if [ -f $PIDFILE ]; then
            echo "CVEDIA RT already running"
            exit 1
        fi
        cd $CVEDIA_DIR
        nohup ./rtservice --webserver --log-console > $LOGFILE 2>&1 &
        echo $! > $PIDFILE
        echo "CVEDIA RT started"
        ;;
    stop)
        echo "Stopping CVEDIA RT..."
        if [ -f $PIDFILE ]; then
            kill $(cat $PIDFILE) 2>/dev/null
            rm -f $PIDFILE
        fi
        pkill -f rtservice 2>/dev/null
        echo "CVEDIA RT stopped"
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    status)
        if [ -f $PIDFILE ] && kill -0 $(cat $PIDFILE) 2>/dev/null; then
            echo "CVEDIA RT is running"
        else
            echo "CVEDIA RT is not running"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
exit 0
