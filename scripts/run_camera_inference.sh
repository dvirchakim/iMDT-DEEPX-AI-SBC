#!/bin/sh
# DeepX Camera Inference Script
# Captures frames from camera and runs AI inference on iMDT V2H SBC

SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR"

export LD_LIBRARY_PATH=$SCRIPT_DIR/lib:/usr/local/lib:$LD_LIBRARY_PATH

# Auto-detect USB camera (skip platform cameras)
CAMERA=""
for dev in /dev/video*; do
    if v4l2-ctl -d $dev --list-formats-ext 2>/dev/null | grep -q "YUYV\|MJPG"; then
        device_info=$(v4l2-ctl --list-devices 2>/dev/null | grep -B1 "$dev" | head -1)
        if echo "$device_info" | grep -qi "usb"; then
            CAMERA=$dev
            break
        fi
    fi
done

if [ -z "$CAMERA" ]; then
    CAMERA="/dev/video2"  # Default fallback
fi

MODEL="assets/models/YoloV7.dxnn"
PARAM=4
OUTPUT_DIR="/tmp/inference_results"
APP="yolo"

mkdir -p $OUTPUT_DIR

echo "DeepX Camera Inference"
echo "======================"
echo "Camera: $CAMERA"
echo "Output: $OUTPUT_DIR"
echo ""
echo "Select model:"
echo "0: YOLOv7 (Object Detection)"
echo "1: YOLOv8N (Object Detection)"
echo "2: YOLOv5S (Object Detection)"
echo "3: YOLOv5S Face (Face Detection)"
echo "4: Pose Estimation"
echo "5: Segmentation"
echo ""
printf "Select (0-5, default 0): "
read sel

case $sel in
    1) MODEL="assets/models/YoloV8N.dxnn"; PARAM=5; APP="yolo";;
    2) MODEL="assets/models/YOLOV5S_1.dxnn"; PARAM=2; APP="yolo";;
    3) MODEL="assets/models/YOLOV5S_Face-1.dxnn"; PARAM=7; APP="yolo";;
    4) MODEL="assets/models/YOLOV5Pose640_1.dxnn"; PARAM=0; APP="pose";;
    5) MODEL="assets/models/DeepLabV3PlusMobileNetV2_2.dxnn"; PARAM=0; APP="segmentation";;
    *) MODEL="assets/models/YoloV7.dxnn"; PARAM=4; APP="yolo";;
esac

echo ""
echo "Running inference with $MODEL..."
echo "Press Ctrl+C to stop"
echo ""

frame_num=0
while true; do
    # Capture frame from camera using GStreamer
    frame_file="/tmp/frame_${frame_num}.jpg"
    gst-launch-1.0 v4l2src device=$CAMERA num-buffers=1 ! videoconvert ! jpegenc ! filesink location=$frame_file 2>/dev/null
    
    if [ -f "$frame_file" ]; then
        # Run inference
        if [ "$APP" = "yolo" ]; then
            ./bin/yolo -m $MODEL -p $PARAM -i $frame_file --fps_only 2>&1 | grep -E "(Detected|BBOX|FPS)"
        elif [ "$APP" = "pose" ]; then
            ./bin/pose -m $MODEL -i $frame_file --fps_only 2>&1 | grep -E "(Detected|keypoint|FPS)"
        else
            ./bin/segmentation -m $MODEL -i $frame_file --fps_only 2>&1 | grep -E "(FPS)"
        fi
        
        # Copy result
        if [ -f "result.jpg" ]; then
            cp result.jpg "$OUTPUT_DIR/result_${frame_num}.jpg"
            echo "Saved: $OUTPUT_DIR/result_${frame_num}.jpg"
        fi
        
        rm -f $frame_file
    fi
    
    frame_num=$((frame_num + 1))
    
    # Limit to 100 frames then wrap
    if [ $frame_num -ge 100 ]; then
        frame_num=0
    fi
done
