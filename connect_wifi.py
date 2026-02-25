import serial
import time

s = serial.Serial('COM3', 115200, timeout=15)

# Connect to WiFi with space in SSID
cmd = '/opt/imdt/wifi/connect-to-access-point.sh "Nisko Guest" "NiskoGuest"\r\n'
s.write(cmd.encode())
time.sleep(15)
data = s.read(5000)
print(data.decode('utf-8', errors='replace'))

# Check connection status
s.write(b'/opt/imdt/wifi/get-connection-status.sh\r\n')
time.sleep(2)
data = s.read(2000)
print(data.decode('utf-8', errors='replace'))

# Get IP
s.write(b'ip addr show wlan0\r\n')
time.sleep(2)
data = s.read(3000)
print(data.decode('utf-8', errors='replace'))

s.close()
