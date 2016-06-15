// cuts
// bitpanic dog star orchestra 12 06/17/16

/*
TO DO
1. CHOPPY TURNS FIELD RECORDING OFF (use systemclock.sched, get current dur of choppy from Bus.getSynchronous)
*/

s.options.memSize = 1048576;
s.boot;


(
///////// SETUP BUFFERS /////////

/* !!!!!!!!!! PUT YOUR SAMPLE'S FILEPATH IN ~bSamp (noisey or wind interferency samples work well, tone oriented stuff not so much!)*/

~bSamp = Buffer.read(s, "/Volumes/MROTHERBACKUP/samples/westinBonaventureFountains.aif", action: { "sample read".postln });

~fft_b1 = Buffer.alloc( s, 2048, 1, completionMessage: { "fft_b1 alloced".postln });
~fft_b2 = Buffer.alloc( s, 2048, 1, completionMessage: { "fft_b2 alloced".postln });
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
	Out.ar( 0, env * mix * amp);
}).add;


SynthDef( \scramble, { | amp = 0.0, cwipe, cwidth, dur = 2, freq = 1.0, glide = 200 trig = 0 |
	var sig, env, play;

	env = EnvGen.kr( Env.linen( 0.001, dur, 0.1, amp ), trig, doneAction: 2 ); // not so sure about this envelope yet
	sig = Crackle.ar( Lag.kr( freq, glide), amp );
	play = IFFT( PV_BinScramble( FFT( ~fft_b2, sig ), Lag.kr( cwipe, glide), 0.1, 0.5 ) ) * env;
	Out.ar( 0, env * play);
}).add;

)


(
///////// START THINGS /////////

// the audio bus
~bus = Bus.audio(s, 1 );

// dry synth
~x = Synth( \play, [ \amp, 0.99, \bufnum, ~bSamp, \effectsBus, ~bus.index, \thresh, 0.5, \trig, 1 ]);

// wet and dry synth together
~y = Synth.after(~x, \delay_blur, [ \amp, 0.9, \delaytime, 2, \glide, 200, \inBus, ~bus.index, \trig, 1 ] );

// choppy control busses
~amp = Bus.control(s, 1).set(0.0);
~dur = Bus.control(s, 1).set(1.0);
~freq = Bus.control(s, 1).set(1.0);
~cwipe = Bus.control(s, 1).set(0.1);
)


(
///////// CONTROL THINGS /////////

// controls for \delay_blur
CCResponder({ |src, chan, num, val|
	switch (num,
		1, {
			("delay_blur amp is" + val.linlin(0, 127, 0.0, 1.0 )).postln;
			~y.set(\amp, val.linlin(0, 127, 0.0, 1.0 ));
		},
		11, {
			("delay_blur dt is" + val.linlin(0, 127, 0.001, 2.0 )).postln;
			~y.set(\delaytime, val.linlin(0, 127, 0.01, 6.0 ));
		}

	)
});

// controls for choppy
CCResponder({ |src, chan, num, val|
	switch (num,
		2, {
			g = val.linlin(0, 127, 0.0, 1.0 );
			("scramble amp is" + g).postln;
			~amp.set(g);
		},
		12, {
			h = val.linlin( 0, 127, 0.9, 1.95);
			("scramble freq is" + h).postln;
			~freq.set(h);
		},
		13, {
			i = val.linlin(0, 127, 0.1, 0.95 );
			("scramble wipe is " + i).postln;
			~cwipe.set(i);
		},
		14, {
			j = val.linlin(0, 127, 0.01, 6 );
			("scramble dur is " + j).postln;
			~dur.set(j);
		},
		15, {
			k = val.linlin(0, 127, 0.001, 0.3 );
			("scramble thresh is" + k).postln;
			~x.set(\thresh, k);
		}
	)
});

OSCFunc({|msg, time, addr |
	if( msg[3] == 1,
		{
		postln( "ONSET!! " );
		Synth.new( \scramble, [ \amp, ~amp.asMap, \cwipe, ~cwipe.asMap, \dur, ~dur.asMap, \freq, ~freq.asMap, \trig, 1 ] );
	});
}, '/trigz');
)


// TO DO

OSCFunc({
// change someone's glide time
});

// glide is controlled by other people


///////// TEST THINGS /////////

~y.set(\delaytime, 0.1);
~y.set(\glide, 200);


///////// CLEANUP THINGS /////////

CCResponder.removeAll;