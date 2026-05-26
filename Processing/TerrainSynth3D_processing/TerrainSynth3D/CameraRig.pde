// Calculates a 3D orbital camera path around the center via mouse rotation and zoom controls.
class CameraRig {
  float azimuth = QUARTER_PI, elevation = radians(39.6), distance = 19;
  float fov = radians(42), camX, camY, camZ;

  // Update Camera Coordinates
  void update() {
    elevation = constrain(elevation, 0.0872, 1.3962); 
    distance  = constrain(distance, 9.0, 38.0);
    
    // Cache angular math operations
    float cosElev = cos(elevation);
    camX =  distance * cosElev * cos(azimuth);
    camY = -distance * sin(elevation);
    camZ =  distance * cosElev * sin(azimuth);
  }

  // Apply Perspective and View Matrices
  void apply(PGraphics g) {
    g.perspective(fov, (float)g.width / g.height, 0.1, 200.0);
    g.camera(camX, camY, camZ, 0, 0, 0, 0, 1, 0);
  }

  // Drag Rotation Input
  void mouseDrag(float dx, float dy) {
    azimuth   -= dx * 0.008;
    elevation += dy * 0.008;
  }

  // Wheel
  void mouseWheel(float delta) {
    distance += delta * 1.4;
  }
}
