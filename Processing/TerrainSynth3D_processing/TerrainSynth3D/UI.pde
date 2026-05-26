// Mouse handling + rendering for viewport, side panel.

float lastMx, lastMy;
boolean dragInView = false;

boolean overViewport(float mx, float my) {
  return mx >= viewX && mx <= viewX + viewW && my >= viewY && my <= viewY + viewH;
}

void mousePressed() {
  if (overViewport(mouseX, mouseY)) { dragInView = true; lastMx = mouseX; lastMy = mouseY; return; }
  if (minimap.over(mouseX, mouseY)) { minimap.handleClick(mouseX, mouseY, orbit); return; }
  for (HorizontalFader f : faders) f.checkMousePressed(mouseX, mouseY);
}

void mouseDragged() {
  if (dragInView) { cam.mouseDrag(mouseX - lastMx, mouseY - lastMy); lastMx = mouseX; lastMy = mouseY; return; }
  if (minimap.over(mouseX, mouseY)) { minimap.handleClick(mouseX, mouseY, orbit); return; }
  for (HorizontalFader f : faders) f.checkMouseDragged(mouseX, mouseY);
}

void mouseReleased() {
  dragInView = false;
  for (HorizontalFader f : faders) f.release();
}

void mouseWheel(MouseEvent e) { if (overViewport(mouseX, mouseY)) cam.mouseWheel(e.getCount()); }

void render3D() {
  cam.update(); view3D.beginDraw(); view3D.background(BG); cam.apply(view3D);
  view3D.ambientLight(60, 60, 55); view3D.directionalLight(220, 220, 200, 0.5, -0.85, -0.35);
  terrain.render(view3D); orbit.render(view3D, terrain, phase); view3D.endDraw();
}

void drawViewport() {
  noStroke(); fill(SURFACE); rect(viewX - 4, viewY - 4, viewW + 8, viewH + 8); image(view3D, viewX, viewY);
}

void drawSidePanel() {
  noStroke();

  // Faders background
  fill(SURFACE);
  rect(rightX, fadersY, SIDE_W, fadersTotalH);

  // Subtle vertical separator between synthesis and effects
  float sepX = rightX + (SIDE_W / 15.0) * 3;
  stroke(BG); strokeWeight(1);
  line(sepX, fadersY + 8, sepX, fadersY + fadersTotalH - 8);
  noStroke();

  for (HorizontalFader f : faders) f.render();

  // Oscilloscope + minimap
  fill(SURFACE);
  rect(rightX, sy, SIDE_W, scopeH);
  rect(rightX, my, SIDE_W, mapH);
  scope.render(rightX + 18, sy + 18, SIDE_W - 36, scopeH - 36, terrain, orbit, phase);
  minimap.render(terrain, orbit);
}
