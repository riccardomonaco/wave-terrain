// =====================================================
// Main
// =====================================================

final color BG = #0c0b0a, SURFACE = #161310, ACCENT = #4ade80, AMBER = #f5f5f0;
final color EFFECT_ACCENT = color(240, 136, 80);
final color REVERB_ACCENT = #60a5fa;
float PAD, SIDE_W, viewX, viewY, viewW, viewH, rightX, phase = 0;
float scopeH, mapH, fadersTotalH, fadersY, sy, my;
int lastTime = 0;

PGraphics view3D; Terrain3D terrain; Orbit3D orbit; CameraRig cam; Oscilloscope scope; Minimap minimap; OscNetworkManager net; PFont font;
HorizontalFader fMidDrive, fHighDrive, fLowDrive, fFeedback, fDelay, fType, fLMX, fMHX, fScale, fRadius, fWaveTerrain;
HorizontalFader fReverbAmt, fRoomSize, fFBFreq, fFBQ;

// faders
  HorizontalFader[] faders;

void settings() { size(2500, 1500, P2D); }

void setup() {
  surface.setLocation(0, 0); surface.setTitle("Terrain Synth 3D"); font = createFont("Consolas", 32, true);
  terrain = new Terrain3D(); orbit = new Orbit3D(); cam = new CameraRig(); scope = new Oscilloscope(256); net = new OscNetworkManager(this);
  layout();
}

void layout() {
  PAD = 14; SIDE_W = constrain(width * 0.32, 480, 720);
  viewX = PAD; viewW = width - SIDE_W - 3 * PAD; viewH = height - 2 * PAD;
  rightX = viewX + viewW + PAD; viewY = PAD;
  view3D = createGraphics((int)viewW, (int)viewH, P3D);

  // Vertical layout
  float gap = 14;
  float totalAvailableH = height - (2 * PAD) - (3 * gap);
  scopeH = mapH = totalAvailableH * 0.20;
  fadersTotalH = totalAvailableH * 0.60;

  fadersY = PAD;
  sy = fadersY + fadersTotalH + gap;
  my = sy + scopeH + gap;
  final int N = 15;
  float colW = SIDE_W / N;

  // Backup current values
  float sV = fScale != null ? fScale.getValue() : 1.5;
  float rV = fRadius != null ? fRadius.getValue() : 2.0;
  int   wV = fWaveTerrain != null ? fWaveTerrain.getIntValue() : 1;
  float midV = fMidDrive != null ? fMidDrive.getValue() : 1.;
  float higV = fHighDrive != null ? fHighDrive.getValue() : 1.;
  float lowV = fLowDrive != null ? fLowDrive.getValue() : 1.;
  float feeV = fFeedback != null ? fFeedback.getValue() : 0.;
  float delV = fDelay != null ? fDelay.getValue() : 1.;
  int   typV = fType != null ? fType.getIntValue() : 0;
  float lmxV = fLMX != null ? fLMX.getValue() : 20.;
  float mhxV = fMHX != null ? fMHX.getValue() : 1000.;
  float ravV = fReverbAmt != null ? fReverbAmt.getValue() : 0.85;
  float rmsV = fRoomSize  != null ? fRoomSize.getValue()  : 0.72;
  float fbfV = fFBFreq    != null ? fFBFreq.getValue()    : 20.;
  float fbqV = fFBQ       != null ? fFBQ.getValue()       : 0.10;

  // faders
  fWaveTerrain = new HorizontalFader(rightX + colW*0,  fadersY, colW, fadersTotalH, "WAVE TERRAIN", 1.0, 4.0);
  fScale       = new HorizontalFader(rightX + colW*1,  fadersY, colW, fadersTotalH, "SCALE",  0.3, 5.0);
  fRadius      = new HorizontalFader(rightX + colW*2,  fadersY, colW, fadersTotalH, "RADIUS", 0.2, 6.0);

  // Drives
  fLowDrive    = new HorizontalFader(rightX + colW*3,  fadersY, colW, fadersTotalH, "LOW DRIVE", 1.0, 250.0);
  fMidDrive    = new HorizontalFader(rightX + colW*4,  fadersY, colW, fadersTotalH, "MID DRIVE", 1.0, 250.0);
  fHighDrive   = new HorizontalFader(rightX + colW*5,  fadersY, colW, fadersTotalH, "HIGH DRIVE", 1.0, 250.0);

  // Effects
  fFeedback    = new HorizontalFader(rightX + colW*6,  fadersY, colW, fadersTotalH, "FEEDBACK", 0.0, 150.0);
  fDelay       = new HorizontalFader(rightX + colW*7,  fadersY, colW, fadersTotalH, "DELAY", 1.0, 250.0);
  fType        = new HorizontalFader(rightX + colW*8,  fadersY, colW, fadersTotalH, "TYPE SELECTOR", 0.0, 2.0);
  fLMX         = new HorizontalFader(rightX + colW*9,  fadersY, colW, fadersTotalH, "LO-MID XOVER", 20.0, 1000.0);
  fMHX         = new HorizontalFader(rightX + colW*10, fadersY, colW, fadersTotalH, "MID-HI XOVER", 1000.0, 20000.0);

  fFBFreq      = new HorizontalFader(rightX + colW*11, fadersY, colW, fadersTotalH, "FB FREQ",    20.0, 20000.0);
  fFBQ         = new HorizontalFader(rightX + colW*12, fadersY, colW, fadersTotalH, "FB Q",       0.1, 10.0);
  fReverbAmt   = new HorizontalFader(rightX + colW*13, fadersY, colW, fadersTotalH, "REVERB AMT", 0.0, 1.0);
  fRoomSize    = new HorizontalFader(rightX + colW*14, fadersY, colW, fadersTotalH, "ROOM SIZE",  0.0, 0.95);

  faders = new HorizontalFader[] {
    fWaveTerrain, fScale, fRadius,
    fLowDrive, fMidDrive, fHighDrive,
    fFeedback, fDelay, fType, fLMX, fMHX,
    fFBFreq, fFBQ, fReverbAmt, fRoomSize
  };

  // Color the effect block
  for (int i = 3; i < faders.length; i++) faders[i].setAccentColor(EFFECT_ACCENT);
  // Reverb pair gets its own blue accent
  fReverbAmt.setAccentColor(REVERB_ACCENT);
  fRoomSize.setAccentColor(REVERB_ACCENT);

  // Restore values
  fScale.setValue(sV); fRadius.setValue(rV); fWaveTerrain.setIntValue(wV);
  fLowDrive.setValue(lowV); fMidDrive.setValue(midV); fHighDrive.setValue(higV);
  fFeedback.setValue(feeV); fDelay.setValue(delV); fType.setIntValue(typV);
  fLMX.setValue(lmxV); fMHX.setValue(mhxV);
  fReverbAmt.setValue(ravV); fRoomSize.setValue(rmsV);
  fFBFreq.setValue(fbfV); fFBQ.setValue(fbqV);

  if (minimap == null) minimap = new Minimap(rightX, my, SIDE_W, mapH);
  else minimap.updatePosition(rightX, my, SIDE_W, mapH);
  lastTime = millis();
}

void windowResized() { layout(); }

void draw() {
  int now = millis(); float dt = (now - lastTime) * 0.001; lastTime = now;
  terrain.setA(fScale.getValue()); orbit.setRadius(fRadius.getValue()); terrain.setWaveNumber(fWaveTerrain.getIntValue());
  phase = (phase + HALF_PI * dt) % TWO_PI;
  background(BG); render3D(); drawViewport(); drawSidePanel();
}

void oscEvent(OscMessage msg) { if (net != null) net.parseIncoming(msg); }
