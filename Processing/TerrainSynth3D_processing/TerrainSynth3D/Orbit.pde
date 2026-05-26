// Renders the orbit on the wave terrain surface
class Orbit3D {
  float cx = 0, cz = 0, r = 2.0;
  final float LIFT = -0.07;

  // Mutate Tracker Vector Nodes
  void setPosition(float cx, float cz) { this.cx = cx; this.cz = cz; }
  void setRadius(float r)              { this.r = max(0.2, r); }

  //Render 3D Scanning Geometries
  void render(PGraphics g, Terrain3D terrain, float phase) {
    int N = 128;
    float invN = 1.0 / N;
    int wave = terrain.waveNumber;
    float yScale = terrain.YSCALE;

    g.noFill();
    g.stroke(AMBER); g.strokeWeight(2.4);
    g.beginShape();

    // Extrude projection points directly matching terrain surface shapes
    for (int i = 0; i <= N; i++) {
      float t = (i * invN) * TWO_PI;
      float x = cx + r * cos(t), z = cz + r * sin(t);
      g.vertex(x, terrain.terrain(wave, x, z) * yScale + LIFT, z);
    }
    g.endShape();
  }
}
