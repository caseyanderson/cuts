// cuts
// bitpanic, dog star orchestra 12, 06/17/16

/*
TO DO
1. can't get open dialogue snip from Scott to work
2. Buffer.readChannels not working?
2. replace PlayBuf with Hollis Frampton moving "window" thing (after Friday)
*/

s.options.memSize = 1048576;
s.boot;


(
Dialog.openPanel({ arg path;
	// path.postln;
~bField = Buffer.readChannel(s, path, channels: [0], action: { |buffer|
"".postln;
"Loaded: ".post;
		// buffer.postln;
path.postln;
"Channels: ".post;
buffer.numChannels.postln;
});

~fft_b1 = Buffer.alloc( s, 2048, 1, completionMessage: { "fft_b1 alloced".postln });
~fft_b2 = Buffer.alloc( s, 2048, 1, completionMessage: { "fft_b2 alloced".postln });
});
)


(

///////// SYNTHDEFS /////////

SynthDef( \play, { | amp = 0.99, bufnum, dur = 1, effectsBus, rate = 1, thresh = 0.5, trig = 1 |
	var chain, env, line, onsets, play, sig;

	env = EnvGen.kr( Env.asr( 0.01, amp, 0.01 ), trig, doneAction: 0 );
	play = PlayBuf.ar( 1, bufnum, rate, loop: 1 );
	chain = FFT(~fft_b1, play );
	onsets = Onsets.kr(chain, thresh, \rcomplex ); // control point on thresh and nothing else here
	SendReply.kr( Impulse.kr( 2 ), '/trigz', [ onsets ] );
	Out.ar( effectsBus, env * play );
}).add;


SynthDef( \delay_blur, { | amp = 0.0, delaytime = 0.0, dur = 4.0, inBus, glide = 200, maxDT = 6, trig = 0 |
	var delay, env, in, mix;

	in = In.ar( inBus, 1 );
	delay = DelayC.ar( in, maxDT, Lag.kr(delaytime, glide), amp, 0.6 );
	env = EnvGen.kr( Env.asr( 0.01, amp, 0.01 ), trig, doneAction: 0 );
	mix = Mix.new([ delay, in ]);
	Out.ar( 1, env * mix * amp);
}).add;


SynthDef( \scramble, { | amp = 0.0, cwipe, cwidth, dur = 2, freq = 1.0, glide = 200, trig = 0 |
	var sig, env, play;

	env = EnvGen.kr( Env.linen( 0.001, dur, 0.1, amp ), trig, doneAction: 2 ); // not so sure about this envelope yet
	sig = Crackle.ar( Lag.kr( freq, glide), amp );
	play = IFFT( PV_BinScramble( FFT( ~fft_b2, sig ), Lag.kr( cwipe, glide), 0.1, 0.5 ) ) * env;
	Out.ar( 1, env * play);
}).add;

)


(
///////// START THINGS /////////

// the audio bus
~bus = Bus.audio(s, 1 );

// wet synth controls
~dbAmp = Bus.control(s, 1).set(0.0);
~dbDelaytime = Bus.control(s, 1).set(2);
~dbTrig = Bus.control(s, 1).set(1);

// choppy control busses
~sAmp = Bus.control(s, 1).set(0.0);
~sDur = Bus.control(s, 1).set(1.0);
~sFreq = Bus.control(s, 1).set(1.0);
~sCwipe = Bus.control(s, 1).set(0.1);

// dry synth
~x = Synth( \play, [ \amp, 0.99, \bufnum, ~bField, \effectsBus, ~bus.index, \thresh, 0.5, \trig, 1 ]);

// wet and dry synth together
~y = Synth.after(~x, \delay_blur, [ \amp, ~dbAmp.asMap, \delaytime, ~dbDelaytime.asMap, \glide, 200, \inBus, ~bus.index, \trig, ~dbTrig.asMap ] );

)


(
///////// CONTROL THINGS /////////

// controls for \delay_blur
CCResponder({ |src, chan, num, val|
	switch (num,
		1, {
			e = val.linlin(0, 127, 0.0, 1.0 );
			("delay_blur amp is" + e).postln;
			~dbAmp.set(e);
		},
		11, {
			f = val.linlin(0, 127, 0.001, 2.0 );
			("delay_blur dt is" + f).postln;
			~dbDelaytime.set(f);
		}

	)
});

// controls for choppy
CCResponder({ |src, chan, num, val|
	switch (num,
		2, {
			g = val.linlin(0, 127, 0.0, 1.0 );
			("scramble amp is" + g).postln;
			~sAmp.set(g);
		},
		12, {
			h = val.linlin( 0, 127, 0.9, 1.95);
			("scramble freq is" + h).postln;
			~sFreq.set(h);
		},
		13, {
			i = val.linlin(0, 127, 0.1, 0.95 );
			("scramble wipe is " + i).postln;
			~sCwipe.set(i);
		},
		14, {
			j = val.linlin(0, 127, 0.01, 6 );
			("scramble dur is " + j).postln;
			~sDur.set(j);
		},
		15, {
			k = val.linlin(0, 127, 0.001, 0.3 );
			("scramble thresh is" + k).postln;
			~x.set(\thresh, k);
		}
	)
});

OSCFunc({|msg, time, addr |
	var dur;
	if( msg[3] == 1,
		{
		postln( "ONSET!! " );

		~dbTrig.set(0); // turn off wet synth
		dur = ~sDur.getSynchronous; // get dur of noise sound to turn synth back on

		Synth.new( \scramble, [ \amp, ~sAmp.asMap, \cwipe, ~sCwipe.asMap, \dur, ~sDur.asMap, \freq, ~sFreq.asMap, \trig, 1 ] ); // play the noise sound

		SystemClock.sched(dur, {
			~dbTrig.set(1);
		});
	});
}, '/trigz');
)


///////// TEST THINGS /////////

~y.set(\delaytime, 0.1);
~y.set(\glide, 200);


///////// CLEANUP THINGS /////////

CCResponder.removeAll;