class HorizontalFader {
  float x, y, w, h;
  String label;
  float minVal, maxVal, valRange;
  private float norm = 0.5;
  private boolean dragging = false;
  color localAccent = #4ade80;

  // Cache data to memory
  private int type;
  private int id;
  private float trackTop, trackBot, trackCX, handleRange;

  // Initialize Fader config
  HorizontalFader(float x, float y, float w, float h, String label, float minVal, float maxVal) {
    this.x = x; this.y = y; this.w = w; this.h = h;
    this.label = label;
    this.minVal = minVal;
    this.maxVal = maxVal;
    this.valRange = maxVal - minVal;

    // Vertical layout zones
    float labelArea = h * 0.22;
    float valueArea = h * 0.10;
    this.trackTop = y + labelArea;
    this.trackBot = y + h - valueArea;
    this.trackCX  = x + w * 0.5;
    this.handleRange = (trackBot - trackTop) - 14; // 7px padding top & bottom inside track

    // Isolate discrete integer selectors from continuous loops
    if (label.equals("WAVE TERRAIN") || label.equals("TYPE SELECTOR")) {
      this.type = 1;
    } else {
      this.type = 0;
    }

    // Map fixed index values for fast event parsing
    if (label.equals("SCALE"))                       id = 0;
    else if (label.equals("RADIUS"))                 id = 1;
    else if (label.equals("WAVE TERRAIN"))           id = 2;
    else if (label.equals("MID DRIVE"))              id = 3;
    else if (label.equals("HIGH DRIVE"))             id = 4;
    else if (label.equals("LOW DRIVE"))              id = 5;
    else if (label.equals("FEEDBACK"))               id = 6;
    else if (label.equals("DELAY"))                  id = 7;
    else if (label.equals("TYPE SELECTOR"))          id = 8;
    else if (label.equals("LO-MID XOVER"))           id = 9;
    else if (label.equals("MID-HI XOVER"))           id = 10;
    else if (label.equals("REVERB AMT"))             id = 11;
    else if (label.equals("ROOM SIZE"))              id = 12;
    else if (label.equals("FB FREQ"))                id = 13;
    else if (label.equals("FB Q"))                   id = 14;
  }

  // Getters and setters
  void setAccentColor(color c) { this.localAccent = c; }
  void setValue(float v)       { norm = (v - minVal) / valRange; }
  float getValue()             { return minVal + norm * valRange; }
  int getIntValue()            { return round(minVal + norm * valRange); }

  void setIntValue(float v) {
    norm = (constrain(round(v), minVal, maxVal) - minVal) / valRange;
  }

  // Boundary Intersection Test
  boolean over(float mx, float my) {
    return mx >= x && mx <= x + w && my >= y && my <= y + h;
  }

  // Render Component Elements
  void render() {
    pushStyle();
    textFont(font);

    // LABEL
    float labelTs = constrain(w * 0.34, 9, 14);
    textSize(labelTs);
    fill(localAccent, 200);
    pushMatrix();
    translate(trackCX, trackTop - 4);
    rotate(-HALF_PI);
    textAlign(LEFT, CENTER);
    text(label, 0, 0);
    popMatrix();

    //TRACK
    float trackW = max(4, w * 0.16);
    float trackX = trackCX - trackW * 0.5;
    float trackH = trackBot - trackTop;
    noStroke();
    fill(BG);
    rect(trackX, trackTop, trackW, trackH, trackW * 0.5);

    // Handle Y from norm
    float handleY = trackBot - 7 - norm * handleRange;

    if (type == 1) {
      int steps = (int)(maxVal - minVal) + 1;
      float stepSpacing = handleRange / max(1, steps - 1);
      int activeIdx = getIntValue() - (int)minVal;
      handleY = trackBot - 7 - activeIdx * stepSpacing;

      // step tick marks on either side of track
      stroke(localAccent, 110);
      strokeWeight(1);
      for (int i = 0; i < steps; i++) {
        float ty = trackBot - 7 - i * stepSpacing;
        line(trackX - 4, ty, trackX - 1, ty);
        line(trackX + trackW + 1, ty, trackX + trackW + 4, ty);
      }
    } else {
      // continuous: fill from handle down to bottom of track
      float fillH = norm * handleRange;
      if (fillH > 0.5) {
        noStroke();
        fill(localAccent, 110);
        rect(trackX, handleY, trackW, (trackBot - 7) - handleY, 0, 0, trackW * 0.5, trackW * 0.5);
      }

      // hash marks beside track every 20%
      stroke(localAccent, 60);
      strokeWeight(1);
      for (int i = 1; i < 5; i++) {
        float ty = trackBot - 7 - (i / 5.0) * handleRange;
        line(trackX - 3, ty, trackX - 1, ty);
        line(trackX + trackW + 1, ty, trackX + trackW + 3, ty);
      }
    }

    //HANDLE CAP
    float capW = w * 0.70;
    float capH = max(10, h * 0.035);
    float capX = trackCX - capW * 0.5;

    // shadow under cap
    noStroke();
    fill(0, 130);
    rect(capX + 1, handleY - capH * 0.5 + 2, capW, capH, 3);

    // outer cap (dark frame)
    fill(#0a0908);
    rect(capX, handleY - capH * 0.5, capW, capH, 3);

    // accent inner panel
    fill(localAccent);
    rect(capX + 2, handleY - capH * 0.5 + 2, capW - 4, capH - 4, 2);

    // central index notch
    stroke(BG);
    strokeWeight(2);
    line(capX + capW * 0.18, handleY, capX + capW * 0.82, handleY);

    //VALUE READOUT
    float valTs = constrain(w * 0.32, 9, 13);
    textSize(valTs);
    noStroke();
    fill(localAccent);
    textAlign(CENTER, BOTTOM);
    String displayValue;
    if (type == 1) {
      displayValue = String.valueOf(getIntValue());
    } else if (maxVal >= 1000) {
      float v = getValue();
      displayValue = (v >= 1000) ? nf(v / 1000.0, 0, 1) + "k" : nf(v, 0, 0);
    } else if (maxVal - minVal < 10) {
      displayValue = nf(getValue(), 0, 2);
    } else {
      displayValue = nf(getValue(), 0, 1);
    }
    text(displayValue, trackCX, y + h - 2);

    popStyle();
  }

  //Peripheral Event Tracking
  void checkMousePressed(float mx, float my) {
    if (over(mx, my)) { dragging = true; updateFromMouse(mx, my); }
  }

  void checkMouseDragged(float mx, float my) {
    if (dragging) updateFromMouse(mx, my);
  }

  void release() { dragging = false; }

  //Map Y coordinate to value and fire OSC
  private void updateFromMouse(float mx, float my) {
    float rawNorm = constrain(1.0 - (my - trackTop - 7) / handleRange, 0, 1);

    if (type == 1) {
      float snappedVal = constrain(round(minVal + rawNorm * valRange), minVal, maxVal);
      norm = (snappedVal - minVal) / valRange;
    } else {
      norm = rawNorm;
    }

    if (net != null) {
      switch(id) {
        case 0:  net.transmit("/fader/scale", getValue()); break;
        case 1:  net.transmit("/fader/radius", getValue()); break;
        case 2:  net.transmit("/fader/waveNumber", getIntValue()); break;
        case 3:  net.transmit("/fader/midDrive", getValue()); break;
        case 4:  net.transmit("/fader/highDrive", getValue()); break;
        case 5:  net.transmit("/fader/lowDrive", getValue()); break;
        case 6:  net.transmit("/fader/feedback", getValue()); break;
        case 7:  net.transmit("/fader/delay", getValue()); break;
        case 8:  net.transmit("/fader/type", (float)getIntValue()); break;
        case 9:  net.transmit("/fader/lowMidFreq", getValue()); break;
        case 10: net.transmit("/fader/midHighFreq", getValue()); break;
        case 11: net.transmit("/fader/reverbAmount", getValue()); break;
        case 12: net.transmit("/fader/roomSize", getValue()); break;
        case 13: net.transmit("/fader/fbFreq", getValue()); break;
        case 14: net.transmit("/fader/fbQ", getValue()); break;
      }
    }
  }
}
