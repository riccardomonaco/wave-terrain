import serial
from pythonosc.udp_client import SimpleUDPClient

PORT = "COM3"          
BAUD = 115200          

SC_IP   = "127.0.0.1"  
SC_PORT = 57120        

arduino = serial.Serial(PORT, BAUD)
osc_sc = SimpleUDPClient(SC_IP, SC_PORT)

prev_sw = 1

while True:
    line = arduino.readline().decode().strip()   
    if not line:
        continue
    try:
        parts = line.split(",")
        jx = int(parts[0])    
        jy = int(parts[1])    
        sw = int(parts[2])    
        ax = int((int(parts[3])-352 )/2)
        ay = int((int(parts[4])-360)/2)    
        az = int((int(parts[5])-375)/2)    
    except (ValueError, IndexError):
        continue   
    
    print(f"Joystick: X={jx}, Y={jy} | Button: {sw} | Accel: X={ax}, Y={ay}, Z={az}")

    osc_sc.send_message("/sensors", [jx, jy, ax, ay, az])
    
    if sw != prev_sw:
        osc_sc.send_message("/btn", sw)
        prev_sw = sw