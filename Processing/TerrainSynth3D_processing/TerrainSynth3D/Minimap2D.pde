// Renders a 2D topographic grid visualization of the 3D terrain and tracks orbital scanning coordinates
class Minimap {
  float x, y, w, h, plotX, plotY, pSize, cell;
  final int RES = 40;

  //Initialize Grid Module
  Minimap(float x, float y, float w, float h) { updatePosition(x, y, w, h); }

  //Recalculate Layout Bounds
  void updatePosition(float x, float y, float w, float h) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    pSize = min(w - 4, h - 4); 
    plotX = x + (w - pSize) * 0.5;
    plotY = y + (h - pSize) * 0.5;
    cell  = pSize / RES;
  }

  //Intersection Boundary Test
  boolean over(float mx, float my) {
    return mx >= plotX && mx <= plotX + pSize && my >= plotY && my <= plotY + pSize;
  }

  //Draw 2D Elevation Map
  void render(Terrain3D terrain, Orbit3D orbit) {
    pushStyle();
    fill(BG); stroke(ACCENT); strokeWeight(1);
    rect(plotX - 2, plotY - 2, pSize + 4, pSize + 4, 4);

    noStroke();
    int wave = terrain.waveNumber;
    
    // Draw height matrix rows and columns
    for (int j = 0; j < RES; j++) {
      float z = map(j, 0, RES - 1, -8, 8);
      float py = plotY + j * cell;
      for (int i = 0; i < RES; i++) {
        float xw = map(i, 0, RES - 1, -8, 8);
        float t = (terrain.terrain(wave, xw, z) + 1) * 0.5;
        fill(lerpColor(#0a1412, #50f078, t)); 
        rect(plotX + i * cell, py, cell + 0.5, cell + 0.5);
      }
    }

    // Project scanning ring vector coordinates
    float scale = pSize / 16.0;
    float cx = plotX + (orbit.cx + 8) * scale;
    float cz = plotY + (orbit.cz + 8) * scale;
    float r2 = orbit.r * scale * 2;
    
    // Draw target indicator lines
    noFill(); stroke(AMBER); strokeWeight(2); ellipse(cx, cz, r2, r2);
    noStroke(); fill(AMBER); ellipse(cx, cz, 6, 6);
    popStyle();
  }

  // Process Click Position Changes
  void handleClick(float mx, float my, Orbit3D orbit) {
    float wx = map(constrain(mx, plotX, plotX + pSize), plotX, plotX + pSize, -8, 8);
    float wz = map(constrain(my, plotY, plotY + pSize), plotY, plotY + pSize, -8, 8);
    float m = orbit.r;
    orbit.setPosition(constrain(wx, -8 + m, 8 - m), constrain(wz, -8 + m, 8 - m));
  }
}
