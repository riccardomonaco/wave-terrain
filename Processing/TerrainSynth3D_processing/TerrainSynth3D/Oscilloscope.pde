// Renders a real-time waveform visualization of the terrain heights along the current orbital modulation path.
class Oscilloscope {
  int N;
  private float[] s;

  //Initialize Waveform Module
  Oscilloscope(int n) {
    N = n;
    s = new float[n];
  }

  //Render Analytic Graph and Timeline
  void render(float x, float y, float w, float h, Terrain3D terrain, Orbit3D orbit, float currentPhase) {
    noStroke(); fill(BG); rect(x, y, w, h, 3);

    float midY = y + h * 0.5;
    float ampY = h * 0.5 - 4.0;
    float invN = 1.0 / N;
    float invN1 = 1.0 / (N - 1);
    int wave = terrain.waveNumber;

    // Draw active scanning track vector points
    noFill(); stroke(ACCENT); strokeWeight(1.5);
    beginShape();
    for (int i = 0; i < N; i++) {
      float t = (i * invN) * TWO_PI;
      float hVal = terrain.terrain(wave, orbit.cx + orbit.r * cos(t), orbit.cz + orbit.r * sin(t));

      float xx = x + (i * invN1) * w;
      float yy = midY - hVal * ampY;
      vertex(xx, yy);
    }
    endShape();
  }
}
