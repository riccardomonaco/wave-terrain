
const int JOY_X  = A3;   // joystick asse X  (analogico)
const int JOY_Y  = A4;   // joystick asse Y  (analogico)
const int JOY_SW = 2;    // joystick pulsante (digitale)

const int ACC_X  = A2;   // MMA7361 asse X (analogico)
const int ACC_Y  = A1;   // MMA7361 asse Y (analogico)
const int ACC_Z  = A0;   // MMA7361 asse Z (analogico)

void setup() {
  Serial.begin(115200);
  pinMode(JOY_SW, INPUT_PULLUP);   
}

void loop() {
  int jx  = analogRead(JOY_X);     // 0–1023
  int jy  = analogRead(JOY_Y);     // 0–1023
  int sw  = digitalRead(JOY_SW);   // 0 o 1

  int ax  = analogRead(ACC_X);     // 0–1023
  int ay  = analogRead(ACC_Y);     // 0–1023
  int az  = analogRead(ACC_Z);     // 0–1023

  Serial.print(jx);  Serial.print(",");
  Serial.print(jy);  Serial.print(",");
  Serial.print(sw);  Serial.print(",");
  Serial.print(ax);  Serial.print(",");
  Serial.print(ay);  Serial.print(",");
  Serial.println(az); 

  delay(20);   
}