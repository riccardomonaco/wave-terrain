// Generates and manages the 3D surface wave terrain using different maths formulas
class Terrain3D {
  final int RES = 120;
  final float SPAN = 16.0, YSCALE = -1.7, EPS = 0.05;
  int waveNumber = 2;
  float a = 1.5, b = 1.0;
  PShape mesh;
  boolean dirty = true;

  // Style
  private final int col1 = #0c0b0a, col2 = #fa8842, col3 = #ffff00, col4 = #4ade80;

  //Update parameters and mark the mesh for updates
  void setA(float v)           { if (abs(v - a) > 0.001) { a = v; dirty = true; } }
  void setB(float v)           { if (abs(v - b) > 0.001) { b = v; dirty = true; } }
  void setWaveNumber(int num)  { if (waveNumber != num)  { waveNumber = num; dirty = true; } }
  float getA()                 { return a; }

  //Wave terrain equations selection
  float terrain(int wave, float x, float z) {
    switch (wave) {
      case 1:  return sin( (z * sin(z) - x * sin(x) * log(z * z + 1)) / a );
      case 2:  return sin(a * (x * x + z * z) );
      case 3:  return sin(sin(a * x * z)/(x * z));
      default: return (sin(a * z * x) + cos(a * (z * z - x * x)))/2;
    }
  }

  //Render the terrain
  void render(PGraphics g) {
    if (dirty) rebuild(g);
    g.shape(mesh);
  }

  //Generate the 3D vertex mesh structure
  private void rebuild(PGraphics g) {
    float step = SPAN / (RES - 1);
    float half = SPAN * 0.5;
    float invEPS = 1.0 / EPS;

    mesh = g.createShape();
    mesh.beginShape(TRIANGLES);
    mesh.noStroke();

    for (int j = 0; j < RES - 1; j++) {
      float z0 = -half + j * step, z1 = z0 + step;
      for (int i = 0; i < RES - 1; i++) {
        float x0 = -half + i * step, x1 = x0 + step;

        // Draw Triangle 1
        addVertexAt(x0, z0, invEPS);
        addVertexAt(x1, z0, invEPS);
        addVertexAt(x0, z1, invEPS);

        // Draw Triangle 2
        addVertexAt(x1, z0, invEPS);
        addVertexAt(x1, z1, invEPS);
        addVertexAt(x0, z1, invEPS);
      }
    }
    mesh.endShape();
    dirty = false;
  }

  // Calculate vertex positions, height, colors, and lighting vectors
  private void addVertexAt(float x, float z, float invEPS) {
    float h = terrain(waveNumber, x, z);
    float dyx = (terrain(waveNumber, x + EPS, z) - h) * invEPS * YSCALE;
    float dyz = (terrain(waveNumber, x, z + EPS) - h) * invEPS * YSCALE;
    float len = sqrt(dyx * dyx + 1.0 + dyz * dyz);

    mesh.normal(-dyx / len, 1.0 / len, -dyz / len);
    mesh.fill(getGradientColor((h + 1.0) * 0.5));
    mesh.vertex(x, h * YSCALE, z);
  }

  //Calculate the multi-stop altitude color blend
  private int getGradientColor(float t) {
    t = constrain(t, 0.0, 1.0);
    if (t < 0.33) return lerpColor(col1, col2, t * 3.0303);          
    if (t < 0.66) return lerpColor(col2, col3, (t - 0.33) * 3.0303); 
    return lerpColor(col3, col4, (t - 0.66) * 2.9412);               
  }
}
