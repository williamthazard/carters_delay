(
Task(
	{
		Server.default = Server.local;
		o = Server.default.options;
		o.memSize_(2.pow(20));
		ServerOptions.devices;
		o.inDevice_("Scarlett 4i4 USB");
		o.outDevice_("Scarlett 4i4 USB");
		s.reboot;
		2.wait;
		~timer = LinkClock.new(2).latency_(Server.default.latency).quantum_(0);
		~player = Array.fill(16, {0});
		~panLFOs = Array.fill(16, {0});
		~ampLFOs = Array.fill(16, {0});
		~cutoffLFOs = Array.fill(16, {0});
		~resonanceLFOs = Array.fill(16, {0});
		~b = Array.fill(16, {0});
		~x = Array.fill(16, {0});
		16.do({
			arg i;
			~b.put(
				i,
				Buffer.alloc(s, s.sampleRate * (~timer.beatDur*(16*(i+1))), 2)
			);
			~b.scramble;
			~x.put(
				i,
				{
					var sig;
					sig = Pan2.ar(SoundIn.ar(0!2));
					RecordBuf.ar(
						sig,
						~b[i],
						\offset.kr(0),
						\reclev.kr(1).varlag(0.3),
						\prelev.kr(-3.dbamp).varlag(0.3),
						\run.kr(1),
						\loop.kr(1)
					);
				}
			);
			~x[i].play;
		});
		Window.closeAll;
		w = Window("superCarter",Window.availableBounds)
		.background_(Color.black)
		.fullScreen
		.onClose_({~topScope.stop; ~bf.free; ~fb.free});
		~bf = Buffer.alloc(s,4096,2);
		~fb = Bus.audio(s,2);
		~topScope = ScopeView(w,
			Rect(0,
				0,
				w.view.bounds.width,
				w.view.bounds.height))
		.bufnum_(~bf.bufnum)
		.server_(Server.default)
		.style_(2)
		.xZoom_(10)
		.yZoom_(10)
		.waveColors_([Color.grey,Color.white])
		.background_(Color.black)
		.start;
		Task({
			SynthDef(\PlayBufPlayer, {
				arg out=0,
				bufnum=0,
				rate=1,
				start=0,
				end=1,
				t_trig=0,
				loops=1,
				amp=0.2,
				pan=0,
				rateSlew=0.1,
				panSlew=1,
				bus=0;
				var snd,
				snd2,
				pos,
				pos2,
				frames,
				duration,
				env,
				sig,
				startA,
				endA,
				startB,
				endB,
				crossfade,
				aOrB;
				aOrB=ToggleFF.kr(t_trig);
				startA=Latch.kr(start,aOrB);
				endA=Latch.kr(end,aOrB);
				startB=Latch.kr(start,1-aOrB);
				endB=Latch.kr(end,1-aOrB);
				crossfade=Lag.ar(K2A.ar(aOrB),0.5);
				rate=Lag.kr(rate,rateSlew)*BufRateScale.kr(bufnum);
				frames=BufFrames.kr(bufnum);
				duration=frames*(end-start)/rate.abs/s.sampleRate*loops;
				env=EnvGen.ar(
					Env.new(
						levels: [0,amp,amp,0],
						times: [0,duration-0.1,0.1],
					),
					gate:t_trig,
				);
				pos=Phasor.ar(
					trig:aOrB,
					rate:rate,
					start:(((rate>0)*startA)+((rate<0)*endA))*frames,
					end:(((rate>0)*endA)+((rate<0)*startA))*frames,
					resetPos:(((rate>0)*startA)+((rate<0)*endA))*frames,
				);
				snd=BufRd.ar(
					numChannels:1,
					bufnum:bufnum,
					phase:pos,
					interpolation:4,
				);
				pos2=Phasor.ar(
					trig:(1-aOrB),
					rate:rate,
					start:(((rate>0)*startB)+((rate<0)*endB))*frames,
					end:(((rate>0)*endB)+((rate<0)*startB))*frames,
					resetPos:(((rate>0)*startB)+((rate<0)*endB))*frames,
				);
				snd2=BufRd.ar(
					numChannels:1,
					bufnum:bufnum,
					phase:pos2,
					interpolation:4,
				);
				sig=Pan2.ar(
					MoogFF.ar(
						in: (crossfade*snd)+((1-crossfade)*snd2) * env,
						freq: \cutoff.kr(12000),
						gain: \resonance.kr(1)),
					pan
				);
				Out.ar(bus!2,sig)
			}).play(s, [\out, 0]);
		}).play;
		2.wait;
		8.do({
			arg i;
			~player.put(i,
				Synth(
					\PlayBufPlayer,
					[\bufnum, ~b[i], \rate, (i+1)*0.25, \bus, ~fb.index]
			));
			~player.put(i+8,
				Synth(
					\PlayBufPlayer,
					[\bufnum, ~b[i+8], \rate, (i+1)*(-0.25), \bus, ~fb.index]
			));
		});
		16.do({
			arg i;
			~panLFOs.put(i,
				Ndef(i.asSymbol, {
					LFTri.kr(~timer.beatDur/rrand(1,64)).range(-1,1)
				})
			);
			~ampLFOs.put(i,
				Ndef(i+16.asSymbol, {
					LFTri.kr(~timer.beatDur/rrand(1,64)).range(0.7,2)
				})
			);
			~cutoffLFOs.put(i,
				Ndef((i+32).asSymbol, {
					LFTri.kr(~timer.beatDur/rrand(1,64)).range(500,12000)
				})
			);
			~resonanceLFOs.put(i,
				Ndef((i+48).asSymbol, {
					LFTri.kr(~timer.beatDur/rrand(1,64)).range(0,2)
				})
			)
		});
		~player.scramble;
		16.do({
			arg i;
			Tdef(i.asSymbol, {
				loop {
					~player[i].set(
						\t_trig,1,
						\start,[0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5].choose,
						\end,[0.55,0.6,0.65,0.7,0.75,0.8,0.85,0.9,0.95].choose,
						\loops,1,
						\amp,~ampLFOs[i],
						\pan, ~panLFOs[i],
						\cutoff, ~cutoffLFOs[i],
						\resonance, ~resonanceLFOs[i]
					);
					~timer.beatDur*[1,2,4,8,16,32,64].wchoose([0.6,0.2,0.1,0.05,0.05]).wait;
				}
			}).play(~timer, quant:4);
		});
		~af = SynthDef("duoscope", { arg bus, bufnum;
			var z;
			z = In.ar(bus, 2);
			ScopeOut2.ar(z, bufnum);
			Out.ar(0, z);
		}).play(
			target: RootNode(Server.default),
			args: [\bus, ~fb.index, \bufnum, ~bf.bufnum],
			addAction: \addToTail
		);
	}
).play(AppClock);
)