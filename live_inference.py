#!/usr/bin/env python3
"""
DeepX Live Camera Inference with Video Display
Captures camera frames, runs YOLO inference via subprocess, displays results
"""

import subprocess
import os
import sys
import time
import signal

# Configuration
CAMERA = "/dev/video2"
MODEL = "assets/models/YoloV7.dxnn"
PARAM = "4"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Set environment
os.environ["LD_LIBRARY_PATH"] = f"{SCRIPT_DIR}/lib:/usr/local/lib:" + os.environ.get("LD_LIBRARY_PATH", "")
os.environ["XDG_RUNTIME_DIR"] = "/run/user/0"
os.environ["WAYLAND_DISPLAY"] = "wayland-0"

def capture_frame(frame_path):
    """Capture a single frame from camera using GStreamer"""
    cmd = [
        "gst-launch-1.0", "-q",
        "v4l2src", f"device={CAMERA}", "num-buffers=1", "!",
        "videoconvert", "!",
        "jpegenc", "!",
        "filesink", f"location={frame_path}"
    ]
    subprocess.run(cmd, capture_output=True)
    return os.path.exists(frame_path)

def run_inference(frame_path):
    """Run YOLO inference on frame"""
    cmd = [
        f"{SCRIPT_DIR}/bin/yolo",
        "-m", f"{SCRIPT_DIR}/{MODEL}",
        "-p", PARAM,
        "-i", frame_path
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return "result.jpg" if os.path.exists(f"{SCRIPT_DIR}/result.jpg") else None

def main():
    print("DeepX Live Camera Inference")
    print("===========================")
    print(f"Camera: {CAMERA}")
    print(f"Model: {MODEL}")
    print("")
    print("Starting live inference stream...")
    print("The video window will open on the display.")
    print("Press Ctrl+C to stop.")
    print("")
    
    os.chdir(SCRIPT_DIR)
    
    # Start GStreamer display pipeline
    display_proc = None
    frame_num = 0
    
    def cleanup(sig=None, frame=None):
        if display_proc:
            display_proc.terminate()
        subprocess.run(["pkill", "-f", "gst-launch.*waylandsink"], capture_output=True)
        sys.exit(0)
    
    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)
    
    try:
        while True:
            frame_path = f"/tmp/frame_{frame_num % 2}.jpg"
            result_path = f"/tmp/result_{frame_num % 2}.jpg"
            
            # Capture frame
            if capture_frame(frame_path):
                # Run inference
                run_inference(frame_path)
                
                # Copy result for display
                if os.path.exists("result.jpg"):
                    subprocess.run(["cp", "result.jpg", result_path], capture_output=True)
                    
                    # Kill previous display and start new one
                    subprocess.run(["pkill", "-f", "gst-launch.*waylandsink"], capture_output=True)
                    
                    display_cmd = [
                        "gst-launch-1.0",
                        "filesrc", f"location={result_path}", "!",
                        "jpegdec", "!",
                        "imagefreeze", "!",
                        "videoconvert", "!",
                        "waylandsink", "sync=false"
                    ]
                    display_proc = subprocess.Popen(display_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                # Cleanup
                os.remove(frame_path) if os.path.exists(frame_path) else None
                
            frame_num += 1
            
    except KeyboardInterrupt:
        cleanup()

if __name__ == "__main__":
    main()
