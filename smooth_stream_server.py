#!/usr/bin/env python3
"""
DeepX Smooth Stream Server
Optimized for smooth video with clear detection overlays
"""

import socket
import subprocess
import os
import threading
import time
import cv2
import numpy as np

PORT = 8888
CAMERA_ID = 2
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__)) or "/tmp/dx_app_package"

MODELS = {
    "yolov7": ("assets/models/YoloV7.dxnn", "4", "YOLOv7"),          # 4: yolov7_640
    "yolov8": ("assets/models/YoloV8N.dxnn", "5", "YOLOv8N"),        # 5: yolov8_640
    "yolov5": ("assets/models/YOLOV5S_1.dxnn", "2", "YOLOv5S"),      # 2: yolov5s_640
    "yolov5x": ("assets/models/YOLOV5X_2.dxnn", "2", "YOLOv5X"),     # 2: yolov5s_640
    "yolov9": ("assets/models/YOLOV9S.dxnn", "10", "YOLOv9S"),       # 10: yolov9_640
    "yolov3": ("assets/models/YOLOV3_1.dxnn", "8", "YOLOv3"),        # 8: yolov3_512
    "yolov4": ("assets/models/YOLOV4_3.dxnn", "9", "YOLOv4"),        # 9: yolov4_416
    "yolox": ("assets/models/YOLOX-S_1.dxnn", "6", "YOLOX-S"),       # 6: yolox_s_512
    "face": ("assets/models/YOLOV5S_Face-1.dxnn", "7", "Face"),      # 7: yolov5s_face_640
}

current_model = "yolov7"
latest_frame = None
latest_result = None
frame_lock = threading.Lock()
running = True

os.environ["LD_LIBRARY_PATH"] = f"{SCRIPT_DIR}/lib:/usr/local/lib:" + os.environ.get("LD_LIBRARY_PATH", "")

HTML_PAGE = b'''<!DOCTYPE html>
<html>
<head>
    <title>DeepX AI Inference</title>
    <style>
        body { font-family: Arial; background: #1a1a2e; color: #eee; margin: 0; padding: 20px; }
        .container { max-width: 900px; margin: 0 auto; text-align: center; }
        h1 { color: #00d4ff; }
        select { padding: 10px; font-size: 16px; margin: 10px; background: #0f3460; color: #fff; border: none; border-radius: 5px; cursor: pointer; }
        #stream { max-width: 100%; border: 3px solid #00d4ff; border-radius: 10px; background: #000; }
        .status { color: #00d4ff; margin: 10px; font-size: 18px; }
        .info { color: #888; font-size: 12px; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>DeepX AI Live Inference</h1>
        <div>
            <select id="model" onchange="changeModel()">
                <option value="yolov7">YOLOv7</option>
                <option value="yolov8">YOLOv8N</option>
                <option value="yolov9">YOLOv9S</option>
                <option value="yolov5">YOLOv5S</option>
                <option value="yolov5x">YOLOv5X</option>
                <option value="yolov4">YOLOv4</option>
                <option value="yolov3">YOLOv3</option>
                <option value="yolox">YOLOX-S</option>
                <option value="face">Face Detection</option>
            </select>
        </div>
        <div><img id="stream" src="/stream" alt="Live Stream"></div>
        <div class="status" id="status">Model: YOLOv7</div>
        <div class="info">DeepX DX-M1 AI Accelerator | iMDT V2H SBC</div>
    </div>
    <script>
        function changeModel() {
            var m = document.getElementById('model').value;
            fetch('/set_model?model=' + m);
            document.getElementById('status').innerText = 'Model: ' + m.toUpperCase();
        }
    </script>
</body>
</html>'''

# Detection results storage
detections = []
det_lock = threading.Lock()

# No smoothing - direct detection display

def parse_detections(output, src_w=640, src_h=480, input_size=640):
    """Parse detection output from yolo binary and scale to original image size"""
    results = []
    
    # Calculate letterbox parameters (same as dx-app preprocessing)
    ratio = min(input_size / src_w, input_size / src_h)
    new_w = int(src_w * ratio)
    new_h = int(src_h * ratio)
    dw = (input_size - new_w) / 2.0
    dh = (input_size - new_h) / 2.0
    
    for line in output.split('\n'):
        if 'BBOX:' in line:
            try:
                # Format: BBOX:class(id) conf, (x1, y1, x2, y2)
                # Example: BBOX:face(0) 0.877982, (205.666, 261.029, 345.391, 445.316)
                parts = line.split('BBOX:')[1]
                class_part = parts.split('(')[0]
                
                # Get confidence - after ") " and before ","
                after_paren = parts.split(') ')[1]
                conf = float(after_paren.split(',')[0])
                
                # Get coordinates - last parentheses group (in letterboxed space)
                coord_str = parts[parts.rfind('(') + 1 : parts.rfind(')')]
                coords = [float(c.strip()) for c in coord_str.split(',')]
                x1, y1, x2, y2 = coords[0], coords[1], coords[2], coords[3]
                
                # Reverse letterbox transformation: subtract padding, then scale
                x1 = (x1 - dw) / ratio
                y1 = (y1 - dh) / ratio
                x2 = (x2 - dw) / ratio
                y2 = (y2 - dh) / ratio
                
                # Clamp to image bounds
                x1 = max(0, min(src_w, x1))
                y1 = max(0, min(src_h, y1))
                x2 = max(0, min(src_w, x2))
                y2 = max(0, min(src_h, y2))
                
                results.append({
                    'class': class_part,
                    'conf': conf,
                    'box': (int(x1), int(y1), int(x2), int(y2))
                })
            except Exception as e:
                print(f"Parse error: {e} - {line}")
    return results

def draw_detections(frame, dets):
    """Draw detection boxes on frame - no smoothing"""
    for det in dets:
        x1, y1, x2, y2 = det['box']
        conf = det['conf']
        label = f"{det['class']} {conf:.0%}"
        
        # Draw thick box
        cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 3)
        
        # Draw label background
        (tw, th), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.7, 2)
        cv2.rectangle(frame, (x1, y1 - th - 10), (x1 + tw + 10, y1), (0, 255, 0), -1)
        
        # Draw label text
        cv2.putText(frame, label, (x1 + 5, y1 - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 2)
    
    return frame

def inference_thread():
    """Run inference in background - maximum speed"""
    global detections, current_model, running
    
    frame_path = "/tmp/inf_frame.jpg"
    last_model = current_model
    
    while running:
        try:
            # Check if model changed - clear detections
            cur_model = current_model  # Local copy to avoid race
            if cur_model != last_model:
                with det_lock:
                    detections = []
                last_model = cur_model
                print(f"*** MODEL SWITCHED TO: {cur_model} ***")
            
            with frame_lock:
                frame = latest_frame
            
            if frame is not None:
                # Save current frame
                cv2.imwrite(frame_path, frame)
                
                # Get current model
                model = MODELS.get(cur_model, MODELS["yolov7"])
                
                # Run inference - no timeout for max speed
                result = subprocess.run([
                    f"{SCRIPT_DIR}/bin/yolo", "-m", f"{SCRIPT_DIR}/{model[0]}", 
                    "-p", model[1], "-i", frame_path
                ], capture_output=True, text=True)
                
                # Parse detections
                dets = parse_detections(result.stdout + result.stderr)
                with det_lock:
                    detections = dets
        except Exception as e:
            print(f"Inference error: {e}")
        
        # No sleep - run as fast as possible

def camera_thread():
    """Continuous camera capture"""
    global latest_frame, running
    
    print(f"Opening camera {CAMERA_ID}...")
    cap = cv2.VideoCapture(CAMERA_ID)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
    cap.set(cv2.CAP_PROP_FPS, 30)
    cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    
    if not cap.isOpened():
        print("Failed to open camera!")
        return
    
    print("Camera ready")
    
    while running:
        ret, frame = cap.read()
        if ret:
            with frame_lock:
                latest_frame = frame.copy()
        time.sleep(0.008)  # faster camera read
    
    cap.release()

def stream_thread(conn):
    """Stream frames to client"""
    global running
    
    boundary = b"--frame"
    header = b"HTTP/1.1 200 OK\r\nContent-Type: multipart/x-mixed-replace; boundary=frame\r\nCache-Control: no-cache\r\n\r\n"
    
    try:
        conn.sendall(header)
        
        while running:
            with frame_lock:
                frame = latest_frame.copy() if latest_frame is not None else None
            
            if frame is not None:
                # Draw detections on frame
                with det_lock:
                    dets = detections.copy()
                
                if dets:
                    frame = draw_detections(frame, dets)
                
                # Encode as JPEG
                _, jpeg = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 75])
                data = jpeg.tobytes()
                
                # Send frame
                frame_data = boundary + b"\r\nContent-Type: image/jpeg\r\nContent-Length: " + str(len(data)).encode() + b"\r\n\r\n" + data + b"\r\n"
                conn.sendall(frame_data)
            
            time.sleep(0.025)  # 40 fps stream
    except:
        pass
    finally:
        try:
            conn.close()
        except:
            pass

def handle_client(conn):
    global current_model
    try:
        request = conn.recv(4096).decode('utf-8', errors='ignore')
        if not request:
            conn.close()
            return
        
        path = request.split('\r\n')[0].split(' ')[1] if ' ' in request else '/'
        
        if path == "/" or path == "/index.html":
            conn.sendall(b"HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n" + HTML_PAGE)
            conn.close()
        elif path == "/stream":
            stream_thread(conn)
        elif path.startswith("/set_model"):
            if "model=" in path:
                model = path.split("model=")[1].split("&")[0].split(" ")[0]
                if model in MODELS:
                    current_model = model
                    print(f"*** MODEL CHANGED TO: {model} ***")
                else:
                    print(f"Unknown model: {model}, available: {list(MODELS.keys())}")
            conn.sendall(b"HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nAccess-Control-Allow-Origin: *\r\n\r\nOK")
            conn.close()
        else:
            conn.sendall(b"HTTP/1.1 404 Not Found\r\n\r\n")
            conn.close()
    except:
        try:
            conn.close()
        except:
            pass

def main():
    global running
    os.chdir(SCRIPT_DIR)
    
    print("DeepX Smooth Stream Server")
    print("==========================")
    
    # Start threads
    threading.Thread(target=camera_thread, daemon=True).start()
    time.sleep(1)
    threading.Thread(target=inference_thread, daemon=True).start()
    time.sleep(1)
    
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("", PORT))
    server.listen(10)
    
    print(f"Ready at http://<board-ip>:{PORT}")
    
    try:
        while running:
            server.settimeout(1.0)
            try:
                conn, _ = server.accept()
                threading.Thread(target=handle_client, args=(conn,), daemon=True).start()
            except socket.timeout:
                continue
    except KeyboardInterrupt:
        pass
    finally:
        running = False
        server.close()

if __name__ == "__main__":
    main()
