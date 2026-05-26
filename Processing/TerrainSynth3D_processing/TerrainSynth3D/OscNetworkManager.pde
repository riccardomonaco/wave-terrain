import oscP5.*;
import netP5.*;

// Manages bidirectional OSC network communication between Processing and SuperCollider for real-time parameter sync.
class OscNetworkManager {
  OscP5 oscP5;
  NetAddress scAddress;
  final int PORT_IN = 9001, PORT_OUT = 57120;
  final String IP_LOCAL = "127.0.0.1";

  //Initialize Network Sockets
  OscNetworkManager(PApplet app) {
    this.oscP5 = new OscP5(app, PORT_IN);
    this.scAddress = new NetAddress(IP_LOCAL, PORT_OUT);
    println("OscNetworkManager: Direct connection bound to SuperCollider on Port " + PORT_OUT);
  }

  //Parse and Route Incoming Messages
  void parseIncoming(OscMessage msg) {
    String pattern = msg.addrPattern();
    if (msg.arguments().length == 0) return;
    float val = msg.get(0).floatValue();

    // Synchronize UI values with incoming commands
    if (pattern.equals("/fader/scale") || pattern.equals("/sc/a"))      fScale.setValue(pattern.equals("/sc/a") ? lerp(0.3, 5.0, val) : val);
    else if (pattern.equals("/fader/radius") || pattern.equals("/sc/radius")) fRadius.setValue(pattern.equals("/sc/radius") ? lerp(0.2, 6.0, val) : val);
    else if (pattern.equals("/fader/waveNumber") || pattern.equals("/sc/terrain")) fWaveTerrain.setIntValue(val);
    else if (pattern.equals("/fader/midDrive"))    fMidDrive.setValue(val);
    else if (pattern.equals("/fader/highDrive"))   fHighDrive.setValue(val);
    else if (pattern.equals("/fader/lowDrive"))    fLowDrive.setValue(val);
    else if (pattern.equals("/fader/feedback"))    fFeedback.setValue(val);
    else if (pattern.equals("/fader/delay"))       fDelay.setValue(val);
    else if (pattern.equals("/fader/type"))        fType.setIntValue(val);
    else if (pattern.equals("/fader/lowMidFreq"))  fLMX.setValue(val);
    else if (pattern.equals("/fader/midHighFreq")) fMHX.setValue(val);
    else if (pattern.equals("/fader/reverbAmount"))fReverbAmt.setValue(val);
    else if (pattern.equals("/fader/roomSize"))    fRoomSize.setValue(val);
    else if (pattern.equals("/fader/fbFreq"))      fFBFreq.setValue(val);
    else if (pattern.equals("/fader/fbQ"))         fFBQ.setValue(val);
    else if (pattern.equals("/sc/cx"))             orbit.setPosition(val * 16.0 - 8.0, orbit.cz);
    else if (pattern.equals("/sc/cy"))             orbit.setPosition(orbit.cx, val * 16.0 - 8.0);
    else if (pattern.equals("/sc/b"))              terrain.setB(lerp(0.1, 2.0, val));
  }

  //Transmit Parameter Updates
  void transmit(String addr, float val) {
    OscMessage msg = new OscMessage(addr);
    msg.add(val);
    oscP5.send(msg, scAddress);
  }
}
