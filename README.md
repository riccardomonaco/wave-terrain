# MultiSaturator

Progetto audio-visivo interattivo basato su wave terrain synthesis, controllato via sensori fisici (joystick + accelerometro). Il segnale audio generato in SuperCollider viene processato da un plugin VST3 custom sviluppato in JUCE, e visualizzato in tempo reale con Processing.

---

## Requisiti

- [JUCE + Projucer](https://juce.com/get-juce/)
- [Visual Studio 202x](https://visualstudio.microsoft.com/) con workload **Desktop development with C++**
- [SuperCollider](https://supercollider.github.io/)
- [Processing 4](https://processing.org/download)
- [Arduino IDE](https://www.arduino.cc/en/software)
- [Python 3](https://www.python.org/downloads/) con `pyserial`: `pip install pyserial`

---

## 1. Compilare il plugin JUCE

1. Apri **Projucer** e carica `JUCE/multiSaturator/multiSaturator.jucer`
2. Clicca **Save and Open in IDE** → si apre Visual Studio
3. Seleziona configurazione **Release | x64**
4. **Build → Build Solution** (`Ctrl+Shift+B`)

Il plugin verrà generato in:
~JUCE/multiSaturator/Builds/VisualStudio2026/x64/Release/VST3/multiSaturator.vst3

---

## 2. SuperCollider — installare VSTPlugin

1. Scarica la libreria da: https://git.iem.at/pd/vstplugin/-/releases
2. Copia la cartella `VSTPlugin` in:
C:/Users/<User>/AppData/Local/SuperCollider/Extensions/
3. Riavvia SuperCollider e verifica con:
```supercollider
VSTPlugin
```

---

## 3. Processing — installare le librerie

Apri Processing, vai su **Sketch → Import Library → Manage Libraries** e installa:

| Libreria | Autore |
|----------|--------|
| **oscP5** | Andreas Schlegel |
| **controlP5** | Andreas Schlegel |

---

## 4. Arduino

1. Apri `Arduino/sketch_may20a/sketch_may20a.ino` con Arduino IDE
2. Seleziona la tua board e porta COM
3. Carica lo sketch sulla board

---

## 5. Script Python (bridge seriale → OSC)

Lo script `Arduino/bridge.py` legge i dati seriali dall'Arduino e li inoltra via OSC a SuperCollider.

1. Installa le dipendenze:
```bash
pip install pyserial
pip install python-osc
```
2. Modifica la porta COM nel file `bridge.py` se necessario (default: `COM3`)
3. Esegui lo script:
```bash
python Arduino/bridge.py
```
Tienilo attivo per tutta la sessione.

---

## 6. Avvio — nell'ordine

1. **Arduino** → carica lo sketch e tieni la board connessa
2. **Python** → esegui `bridge.py`
3. **Processing** → apri ed esegui `Processing/TerrainSynth3D_processing/TerrainSynth3D/TerrainSynth3D.pde`
4. **SuperCollider** → apri `SuperCollider/waveterrain.scd`, esegui prima:
```supercollider
s.boot;
```
poi esegui il blocco principale `( ... )`

---

## Struttura del progetto
MultiSaturator/
├── Arduino/
│   ├── sketch_may20a/      # Sketch Arduino (joystick + accelerometro)
│   └── bridge.py           # Bridge seriale → OSC
├── JUCE/
│   └── multiSaturator/     # Sorgenti plugin VST3
│       └── Source/
├── Processing/
│   └── TerrainSynth3D_processing/  # Visualizzazione grafica OSC
└── SuperCollider/
└── waveterrain.scd  # Engine audio principale
