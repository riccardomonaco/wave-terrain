s.quit;
s.scope;
s.boot;

(

s.waitForBoot({

    ~b_cx = Bus.control(s, 1).set(0.5);
    ~b_cy = Bus.control(s, 1).set(0.5);
    ~b_r = Bus.control(s, 1).set(0.5);
    ~b_a = Bus.control(s, 1).set(0.5);
    ~b_b = Bus.control(s, 1).set(0.5);

    ~vstBus = Bus.audio(s, 2);

    SynthDef("vst_fx", { |inBus, outBus = 0|
        var sig = In.ar(inBus, 2);
        var vstSig = VSTPlugin.ar(sig, 2);
        Out.ar(outBus, vstSig);
    }).add;

    s.sync;

	//Terrain definition
    ~terrains = (
        wave1: (
            func: { |x, y, a, b| sin((x*sin(x) - (y*sin(y) * log(x * x + 1))) / a) },
            makeX: { |norm| norm.linlin(-1, 1, -20, 20) },
            makeY: { |norm| norm.linlin(-1, 1, -20, 20) },
            makeR: { |norm| norm.linlin(0, 1, 0, 5) },
            makeA: { |norm| LFSaw.kr(norm.linlin(0, 1, 0.05, 100)).range(1, 10) },
            makeB: { |norm| norm.linlin(0, 1, 0.1, 2) },
            baseFreq: [800, 1000.4],
            amp: 1,
            lim: 0.2
        ),
        vivisciolto: (
            func: { |x, y, a, b| sin(a*(x*x+y*y)) },
            makeX: { |norm| norm.linlin(-1, 1, -20, 20) },
            makeY: { |norm| norm.linlin(-1, 1, -20, 20) },
            makeR: { |norm| norm.linlin(0, 1, 0, 5) },
            makeA: { |norm| LFSaw.kr(norm.linlin(0, 1, 0.05, 20)).range(1, 10) },
            makeB: { |norm| norm.linlin(0, 1, 0.5, 10) },
            baseFreq: [40, 40.5],
            amp: 1,
            lim: 0.2
        ),


		ritmo1: (
			            func: { |x, y, a, b| sin(sin(a*x*y)/(x*y))},
            makeX: { |norm| norm.linlin(0, 1, -10, 10) },
            makeY: { |norm| norm.linlin(0, 1, -10, 10) },
            makeR: { |norm| norm.linlin(0, 1, 0, 5) },
            makeA: { |norm| norm.linlin(0, 1, 1, 8) },
            makeB: { |norm| norm.linlin(0, 1, 1, 8) },
            baseFreq: [60, 60.5],
            amp: 2.5,
            lim: 0.8
        ),

        extra: (
			func: { |x, y, a, b| (sin(a*(y*x))+cos(a*(x*x-y*y)))/2 },
            makeX: { |norm| norm.linlin(0, 1, -20, 20) },
            makeY: { |norm| norm.linlin(0, 1, -20, 20) },
            makeR: { |norm| norm.linlin(0, 1, 0.1, 2) },
            makeA: { |norm| norm.linlin(0, 1, 0.1, 2) },
            makeB: { |norm| norm.linlin(0, 1, 0.5, 10) },
            baseFreq: [20, 21],
            amp: 1,
            lim: 0.2
        )
    );

    ~terrainNames = [\wave1, \vivisciolto, \ritmo1, \extra]; //Sequence
    ~currentIndex = 0;
    ~isLayered = false;

    ~getTerrainFunc = { |name|
        {
            var t = ~terrains[name];
            var norm_cx = In.kr(~b_cx, 1).lag(0.1);
            var norm_cy = In.kr(~b_cy, 1).lag(0.1);
            var norm_r  = In.kr(~b_r, 1).lag(0.1);
            var norm_a  = In.kr(~b_a, 1).lag(0.1);
            var norm_b  = In.kr(~b_b, 1).lag(0.1);

            var cx = t[\makeX].value(norm_cx);
            var cy = t[\makeY].value(norm_cy);
            var r  = t[\makeR].value(norm_r);
            var a  = t[\makeA].value(norm_a);
            var b  = t[\makeB].value(norm_b);

			var baseF = t[\baseFreq];
			var adaptedFreq = baseF / (1 + (r * 2));

            var phi = LFSaw.ar(adaptedFreq, -1).range(0, 2pi);

			var x = cx  + (r * cos(phi));
			var y = cy  + (r * sin(phi));


            var sig = t[\func].value(x, y, a, b) * t[\amp]; //Coordinates to sound
            Limiter.ar(sig, t[\lim])
        }
    };

    ~loadTerrain = { |name|
        Ndef(\myTerrain, ~getTerrainFunc.value(name));
    };

    ~fxSynth = Synth("vst_fx", [\inBus, ~vstBus, \outBus, 0], addAction: 'addToTail');
    ~vst = VSTPluginController(~fxSynth);

	//Put your vst3 path here
    ~vst.open("C:\\Users\\Dev\\Documents\\MultiSaturator\\JUCE\\multiSaturator\\Builds\\VisualStudio2026\\x64\\Release\\VST3\\multiSaturator.vst3\\Contents\\x86_64-win\\multiSaturator.vst3", action: {
        AppClock.sched(0.2, {
            ~vst.gui;
            ~vst.info.print;
            nil;
        });
    });

    Ndef(\myTerrain).fadeTime = 2;
    ~loadTerrain.value(~terrainNames[~currentIndex]);
    Ndef(\myTerrain).play(~vstBus);

OSCdef.freeAll;

~procAddr = NetAddr("127.0.0.1", 9001);
~waveState = 1;


~smoothed = (ax: 0.0, ay: 0.0, az: 0.0);
~smoothFactor = 0.85;   // change this for different types of smoothing
OSCdef(\sensorInput, { |msg|
    var jx = msg[1].linlin(0, 1023, 0.0, 1.0);
    var jy = msg[2].linlin(0, 1023, 0.0, 1.0);
		var ax = (msg[3]).linlin(-23, 23, 1.0, -1.0).poll;
		var ay = (msg[4]).linlin(-23, 23, -1.0, 1.0).poll;
		var az = (msg[5]).linlin(-23, 23, -1.0, 1.0).poll;

	~smoothed[\ax] = (~smoothed[\ax] * ~smoothFactor) + (ax * (1 - ~smoothFactor));
    ~smoothed[\ay] = (~smoothed[\ay] * ~smoothFactor) + (ay * (1 - ~smoothFactor));
    ~smoothed[\az] = (~smoothed[\az] * ~smoothFactor) + (az * (1 - ~smoothFactor));

    ~b_r.set(jx);
    ~b_a.set(jy);
    ~b_cx.set(~smoothed[\ax]);
    ~b_cy.set(~smoothed[\ay]);
    ~b_b.set(~smoothed[\az]);

    ~procAddr.sendMsg('/sc/radius', jx);
    ~procAddr.sendMsg('/sc/a', jy);
	~procAddr.sendMsg('/sc/cx', ~smoothed[\ax].linlin(-1.0,1.0,0.0,1.0));
	~procAddr.sendMsg('/sc/cy', ~smoothed[\ay].linlin(-1.0,1.0,0.0,1.0));
}, '/sensors');

OSCdef(\buttonInput, { |msg|
// 0 --> click
    if(msg[1] == 0) {
        ~waveState = (~waveState % 4) + 1;
        ~currentIndex = (~currentIndex + 1) % ~terrainNames.size;

        Ndef(\myTerrain, ~getTerrainFunc.value(~terrainNames[~currentIndex]));

        ~procAddr.sendMsg('/fader/waveNumber', ~waveState.asFloat);

        ("Switch a Terrain: " ++ ~terrainNames[~currentIndex]).postln;
    };
}, '/btn');

OSCdef(\setlowDrive, { |msg|
    if(~vst.notNil) { ~vst.set(0, msg[1].linlin(1.0, 250.0, 0.0, 1.0)); };
}, '/fader/lowDrive');

OSCdef(\setMidDrive, { |msg|
    if(~vst.notNil) { ~vst.set(1, msg[1].linlin(1.0, 250.0, 0.0, 1.0)); };
}, '/fader/midDrive');

OSCdef(\setHighDrive, { |msg|
    if(~vst.notNil) { ~vst.set(2, msg[1].linlin(1.0, 250.0, 0.0, 1.0)); };
}, '/fader/highDrive');

OSCdef(\setLowMidFreq, { |msg|
    if(~vst.notNil) { ~vst.set(3, msg[1].linlin(20.0, 1000.0, 0.0, 1.0)); };
}, '/fader/lowMidFreq');

OSCdef(\setMidHighFreq, { |msg|
    if(~vst.notNil) { ~vst.set(4, msg[1].linlin(1000.0, 20000.0, 0.0, 1.0)); };
}, '/fader/midHighFreq');

OSCdef(\setFeedback, { |msg|
    if(~vst.notNil) { ~vst.set(5, msg[1].linlin(0.0, 150.0, 0.0, 1.0)); };
}, '/fader/feedback');

OSCdef(\setDelay, { |msg|
    if(~vst.notNil) { ~vst.set(6, msg[1].linlin(1.0, 250.0, 0.0, 1.0)); };
}, '/fader/delay');

OSCdef(\setReverbAmount, { |msg|
    if(~vst.notNil) { ~vst.set(7, msg[1].linlin(0.0, 1.0, 0.0, 1.0)); };
}, '/fader/reverbAmount');

OSCdef(\setRoomSize, { |msg|
    if(~vst.notNil) { ~vst.set(8, msg[1].linlin(0.0, 0.95, 0.0, 1.0)); };
}, '/fader/roomSize');

OSCdef(\setFbFreq, { |msg|
    if(~vst.notNil) { ~vst.set(9, msg[1].linlin(20.0, 20000.0, 0.0, 1.0)); };
}, '/fader/fbFreq');

OSCdef(\setFbQ, { |msg|
    if(~vst.notNil) { ~vst.set(10, msg[1].linlin(0.1, 10.0, 0.0, 1.0)); };
}, '/fader/fbQ');

OSCdef(\setType, { |msg|
    if(~vst.notNil) { ~vst.set(11, msg[1].linlin(0, 2, 0.0, 1.0)); };
}, '/fader/type');

});
)

s.quit;