# Live coding example for Retune conference 2014
# 1) Press Run (Cmd+R) to start
# 2) Make changes (e.g. comment in/out various lines in :beats & :amen)
# 3) Press Run again (changes will only be audible from next queue point)

# compute loop length (4 bars), bar & quarter note durations
dur = sample_duration :loop_compus
bar = dur / 4
quart = dur / 16

# this (and other functions) run each in its own thread
# synchronizes all others, also plays a v.simple beat
define :heartbeat do
  cue :loop
  cue :bar
  sample :drum_heavy_kick
  3.times do
    sleep bar
    cue :bar
  end
  # wait another 3/4 of a bar
  sleep quart * 3
  sample :drum_heavy_kick
  # complete 4-bar loop (wait for another 1/4 note)
  sleep quart
end

# this function is sync'ed to single bars and creates an arpeggio
# with a syncopated delay and filter modulation
define :arp do
  sync :bar
  with_fx :echo, phase: dur / 12, decay: dur, mix: 0.9 do
    use_synth :prophet
    play_pattern_timed [:C3, :Eb2, :G2, :Ab2], [quart,quart,quart,quart/2],
      cutoff: rrand(60,110), res: rrand(0.01,0.25),
      amp: 0.25, env_curve: 2, decay: 0.25,
      sustain: 0.5, sustain_level: 0
  end
end

# drum loop (also with delay)
define :beats do
  sync :loop
  with_fx :echo, phase: quart * 3, decay: dur, mix: 0.6 do
    # make sure only one of the following 3 lines is active
    # (uncommented) at a time
    #sample :loop_compus, rate: 0.5
    #sample :loop_compus, rate: 1
    sample :loop_compus, rate: [0.25, 0.5, 1, 1, 1].choose if rand < 0.9
  end
end

# let's add ye good ol' amen break
# first compute playback rate so it matches other drum loop
ar = (sample_duration :loop_amen_full) / dur

define :amen do
  sync :loop
  # again make sure only one of these lines is active to avoid ensuing craziness
  #sample :loop_amen_full, amp: 0.5, rate: ar
  #sample :loop_amen_full, amp: 0.5, rate: -ar
  #sample :loop_amen_full, amp: 0.5, rate: ar/2
  sample :loop_amen_full, amp: 0.5, rate: [ar, ar/2].choose if rand < 0.5
  #sample :loop_amen_full, amp: 0.5, start: 0.5, rate: -ar; sleep dur / 2
end

# finally, some lovely stacked chords to add a bit of space
# uses nested effects and randomly chooses chords from pool of options
define :stacks do
  use_synth :supersaw
  vol = 0.42
  with_fx :reverb, room: 0.9 do
    with_fx :slicer, phase: quart do
      sync :loop
      play_chord [[:C2, :Eb3, :Ab4],[:D2, :F3, :Ab4]].choose,
        cutoff: rrand(100,130), pan: -0.25,
        amp: vol, env_curve: 7, decay: bar, release: bar
    end
    sleep bar * 2
    with_fx :slicer, phase: quart do
      play_chord [[:C3, :Eb3, :G3],[:Bb2, :Eb3, :G3]].choose,
        cutoff: rrand(100,130), pan: 0.25,
        amp: vol, env_curve: 7, decay: bar, release: bar
    end
  end
end

# altogether now...
in_thread(name: :t1){loop{heartbeat}}
in_thread(name: :t2){loop{arp}}
in_thread(name: :t3){loop{beats}}
in_thread(name: :t4){loop{amen}}
in_thread(name: :t5){loop{stacks}}