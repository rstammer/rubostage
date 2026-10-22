# Exported from rubostage. The next export overwrites this file;
# to work on it by hand, take this line out first.
#
#   bin/play examples/crawling/live.rb
#
# The form plays through by itself. Commands land at the next section
# boundary; each needs a new first number:
#
#   bin/play -e 'set :stage_cmd, [2, :repeat, nil]'
#   bin/play -e 'set :stage_cmd, [3, :next, nil]'
#   bin/play -e 'set :stage_cmd, [4, :jump, 0]'
#   bin/play -e 'set :stage_cmd, [5, :end, nil]'
#
# To loop the form instead of ending it:
#
#   bin/play -e 'set :stage_loop, true'

# Crawling — Linkin Park
#
# Arranged from rubostage. Key C#m, 105 BPM.
# Form: Intro – Verse – Pre-Chorus – Chorus – Verse – Pre-Chorus – Chorus – Bridge – Chorus – Outro.
#
# use_bpm sits above the live_loops: it is thread-local, and loops inherit
# it when they are created.

use_bpm 105

# Each section once: [bass note, voicing, beats] per chord
sections = [
  [
    [37, [61, 64, 68], 4], # Intro: C#m
    [45, [61, 64, 69], 4], # Intro: A
    [40, [59, 64, 68], 4], # Intro: E
    [47, [59, 63, 66], 4], # Intro: B
    [37, [61, 64, 68], 4], # Intro: C#m
    [45, [61, 64, 69], 4], # Intro: A
    [40, [59, 64, 68], 4], # Intro: E
    [47, [59, 63, 66], 4], # Intro: B
  ],
  [
    [37, [61, 64, 68], 4], # Verse: C#m
    [45, [61, 64, 69], 4], # Verse: A
    [40, [59, 64, 68], 4], # Verse: E
    [47, [59, 63, 66], 4], # Verse: B
    [37, [61, 64, 68], 4], # Verse: C#m
    [45, [61, 64, 69], 4], # Verse: A
    [40, [59, 64, 68], 4], # Verse: E
    [47, [59, 63, 66], 4], # Verse: B
  ],
  [
    [45, [61, 64, 69], 4], # Pre-Chorus: A
    [40, [59, 64, 68], 4], # Pre-Chorus: E
    [47, [59, 63, 66], 4], # Pre-Chorus: B
    [47, [59, 63, 66], 4], # Pre-Chorus: B
  ],
  [
    [37, [61, 64, 68], 4], # Chorus: C#m
    [45, [61, 64, 69], 4], # Chorus: A
    [40, [59, 64, 68], 4], # Chorus: E
    [47, [59, 63, 66], 4], # Chorus: B
    [37, [61, 64, 68], 4], # Chorus: C#m
    [45, [61, 64, 69], 4], # Chorus: A
    [40, [59, 64, 68], 4], # Chorus: E
    [47, [59, 63, 66], 4], # Chorus: B
  ],
  [
    [45, [61, 64, 69], 4], # Bridge: A
    [40, [59, 64, 68], 4], # Bridge: E
    [47, [59, 63, 66], 4], # Bridge: B
    [37, [61, 64, 68], 4], # Bridge: C#m
    [45, [61, 64, 69], 4], # Bridge: A
    [40, [59, 64, 68], 4], # Bridge: E
    [47, [59, 63, 66], 4], # Bridge: B
    [47, [59, 63, 66], 4], # Bridge: B
  ],
  [
    [37, [61, 64, 68], 4], # Outro: C#m
    [45, [61, 64, 69], 4], # Outro: A
    [40, [59, 64, 68], 4], # Outro: E
    [47, [59, 63, 66], 4], # Outro: B
    [37, [61, 64, 68], 4], # Outro: C#m
  ]
]

# The order they are played in, as indexes into sections
form = [0, 1, 2, 3, 1, 2, 3, 4, 3, 5]

# Where each form position starts, counted in chords, for the stage
offsets = [0, 8, 16, 20, 28, 36, 40, 48, 56, 64]

# The closing chord: [bass note, voicing]
final = [37, [61, 64, 68]]

# Per section: which chord sounds on each beat, as an index into its chords
beats_at = [[0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7], [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7], [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3], [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7], [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7], [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4]]

# Per section: energy, swing, guitar part and patterns. Drums are [step,
# velocity] within a bar; bass is [step, interval]; comp is the guitar rhythm.
parts = [
  {energy: 1, swing: 0.0, fill: false, guitar: :none,
   kick: [[0, 1.0], [10, 0.75], [14, 0.6]], snare: [[8, 1.0]],
   hat: [[0, 0.8], [2, 0.5], [4, 0.5], [6, 0.5], [8, 0.8], [10, 0.5], [12, 0.5], [14, 0.5]], open_hat: [],
   bass: [[0, 0]], comp: [], pad: true}, # Intro
  {energy: 1, swing: 0.0, fill: false, guitar: :stabs,
   kick: [[0, 1.0], [10, 0.75], [14, 0.6]], snare: [[8, 1.0]],
   hat: [[0, 0.8], [2, 0.5], [4, 0.5], [6, 0.5], [8, 0.8], [10, 0.5], [12, 0.5], [14, 0.5]], open_hat: [],
   bass: [[0, 0], [6, 0], [8, 0]], comp: [0, 8, 10], pad: true}, # Verse
  {energy: 2, swing: 0.0, fill: true, guitar: :palm,
   kick: [[0, 1.0], [8, 0.95], [10, 0.7]], snare: [[4, 1.0], [12, 1.0]],
   hat: [[0, 0.8], [2, 0.5], [4, 0.8], [6, 0.5], [8, 0.8], [10, 0.5], [12, 0.8], [14, 0.5]], open_hat: [],
   bass: [[0, 0], [2, 0], [4, 0], [6, 0], [8, 0], [10, 0], [12, 0], [14, 0]], comp: [0, 2, 4, 6, 8, 10, 12, 14], pad: true}, # Pre-Chorus
  {energy: 3, swing: 0.0, fill: false, guitar: :power,
   kick: [[0, 1.0], [8, 0.95], [10, 0.7]], snare: [[4, 1.0], [12, 1.0]],
   hat: [[0, 0.8], [2, 0.5], [4, 0.8], [6, 0.5], [8, 0.8], [10, 0.5], [12, 0.8], [14, 0.5]], open_hat: [],
   bass: [[0, 0], [2, 0], [3, 0], [6, 0], [8, 0], [10, 0], [11, 0], [14, 0], [15, 7]], comp: [0, 3, 6, 8, 11, 14], pad: false}, # Chorus
  {energy: 2, swing: 0.0, fill: true, guitar: :palm,
   kick: [[0, 1.0], [10, 0.75], [14, 0.6]], snare: [[8, 1.0]],
   hat: [[0, 0.8], [2, 0.5], [4, 0.5], [6, 0.5], [8, 0.8], [10, 0.5], [12, 0.5], [14, 0.5]], open_hat: [],
   bass: [[0, 0], [2, 0], [6, 0], [8, 0], [10, 0], [14, 7]], comp: [0, 2, 3, 6, 8, 10, 11, 14], pad: true}, # Bridge
  {energy: 3, swing: 0.0, fill: false, guitar: :power,
   kick: [[0, 1.0], [8, 0.95], [10, 0.7]], snare: [[4, 1.0], [12, 1.0]],
   hat: [[0, 0.8], [2, 0.5], [4, 0.8], [6, 0.5], [8, 0.8], [10, 0.5], [12, 0.8], [14, 0.5]], open_hat: [],
   bass: [[0, 0], [2, 0], [3, 0], [6, 0], [8, 0], [10, 0], [11, 0], [14, 0], [15, 12]], comp: [0, 3, 6, 8, 11, 14], pad: true}, # Outro
]

# Loudness per energy level
levels = [0, 0.4, 0.6, 0.8]

set :stage_next, 0
set :stage_seen, (get[:stage_cmd] || [0])[0]

# Four clicks lead in.
4.times do
  sample :drum_cymbal_closed, amp: 0.8
  sleep 1
end

# Offbeat eighths (step 2 of every beat) come late by the section's swing.
live_loop :drums do
  pos = sync(:section)[0]
  if pos < 0
    sample :drum_cymbal_hard, amp: 0.7
    sample :drum_heavy_kick, amp: 0.9
    stop
  end
  part = parts[form[pos]]
  level = levels[part[:energy]]
  sample :drum_cymbal_hard, amp: 0.5 * level if part[:energy] > 1
  slots = beats_at[form[pos]].length * 4
  slots.times do |slot|
    step = slot % 16
    late = (step % 4 == 2) ? part[:swing] * 0.5 : 0
    time_warp late do
      if part[:fill] && slot >= slots - 8
        # Tom fill over the last two beats, down the kit.
        toms = [:drum_tom_hi_hard, :drum_tom_hi_hard, :drum_tom_mid_hard, :drum_tom_mid_hard,
          :drum_tom_lo_hard, :drum_tom_lo_hard, :drum_snare_hard, :drum_snare_hard]
        sample toms[slot - (slots - 8)], amp: 0.75 * level
      else
        kick = part[:kick].find { |s, _vel| s == step }
        if kick
          sample :drum_bass_hard, amp: 0.85 * kick[1] * level
          sample :drum_heavy_kick, amp: 0.4 * kick[1] * level if part[:energy] == 3
        end
        snare = part[:snare].find { |s, _vel| s == step }
        if snare
          sample :drum_snare_hard, amp: 0.75 * snare[1] * level
          sample :sn_dolf, amp: 0.25 * snare[1] * level if snare[1] > 0.5
        end
        open_hat = part[:open_hat].find { |s, _vel| s == step }
        hat = part[:hat].find { |s, _vel| s == step }
        if open_hat
          sample :drum_cymbal_open, amp: 0.3 * open_hat[1] * level, sustain: 0.1, release: 0.25
        elsif hat
          sample :drum_cymbal_closed, amp: 0.3 * hat[1] * level
        end
      end
    end
    sleep 0.25
  end
end

live_loop :bass do
  pos = sync(:section)[0]
  use_synth :subpulse
  if pos < 0
    play final[0], release: 3, amp: 0.6
    stop
  end
  part = parts[form[pos]]
  chords = sections[form[pos]]
  at = beats_at[form[pos]]
  with_fx :lpf, cutoff: [0, 75, 90, 100][part[:energy]] do
    (at.length * 4).times do |slot|
      step = slot % 16
      hit = part[:bass].find { |s, _interval| s == step }
      if hit
        late = (step % 4 == 2) ? part[:swing] * 0.5 : 0
        time_warp late do
          play chords[at[slot / 4]][0] + hit[1], release: 0.3, amp: 0.6 * levels[part[:energy]]
        end
      end
      sleep 0.25
    end
  end
end

# The guitar part: distorted power chords (root, fifth, octave), palm
# mutes, an open strum, short stabs, or nothing. One detuned saw per note
# gives the width a doubled take would; two would overload the engine.
live_loop :comp do
  pos = sync(:section)[0]
  if pos < 0
    use_synth :pluck
    final[1].each { |n| play n, amp: 0.4, release: 3 }
    stop
  end
  part = parts[form[pos]]
  level = levels[part[:energy]]
  chords = sections[form[pos]]
  at = beats_at[form[pos]]
  dirty = [:power, :palm].include?(part[:guitar])
  with_fx :distortion, distort: 0.85, mix: (dirty ? 1 : 0) do
    with_fx :lpf, cutoff: ((part[:guitar] == :palm) ? 72 : 100) do
      (at.length * 4).times do |slot|
        step = slot % 16
        if part[:comp].include?(step) && part[:guitar] != :none
          root = chords[at[slot / 4]][0]
          voicing = chords[at[slot / 4]][1]
          late = (step % 4 == 2) ? part[:swing] * 0.5 : 0
          time_warp late do
            case part[:guitar]
            when :power, :palm
              hold = (part[:guitar] == :palm) ? 0.12 : 0.45
              use_synth :dsaw
              play [root + 12, root + 19, root + 24], release: hold, amp: 0.25 * level, detune: 0.15
            when :strum
              use_synth :pluck
              voicing.each_with_index do |n, i|
                time_warp i * 0.02 do
                  play n, amp: 0.4 * level, release: 1
                end
              end
            when :stabs
              use_synth :blade
              play voicing, release: 0.15, amp: 0.3 * level
            end
          end
        end
        sleep 0.25
      end
    end
  end
end

live_loop :pad do
  pos = sync(:section)[0]
  use_synth :dark_ambience
  if pos < 0
    play final[1], attack: 0.1, release: 4, amp: 0.2, cutoff: 90
    stop
  end
  part = parts[form[pos]]
  with_fx :reverb, room: 0.8, mix: 0.4 do
    sections[form[pos]].each do |_root, voicing, beats|
      play voicing, attack: 0.2, release: beats * 0.95, amp: 0.18 * levels[part[:energy]], cutoff: 90 if part[:pad]
      sleep beats
    end
  end
end

# Decides what comes next and cues it. Defined last, so every voice above
# is already waiting on :section when the first cue fires.
live_loop :conductor do
  pos = get[:stage_next]
  cue :section, pos
  
  stop if pos < 0
  sections[form[pos]].each_with_index do |(_root, _voicing, beats), index|
    sleep beats
  end
  following = pos + 1
  cmd = get[:stage_cmd]
  if cmd && cmd[0] != get[:stage_seen]
    set :stage_seen, cmd[0]
    following = pos if cmd[1] == :repeat
    following = cmd[2] if cmd[1] == :jump
    following = -1 if cmd[1] == :end
  end
  following = (get[:stage_loop] ? 0 : -1) if following >= form.length
  set :stage_next, following
end
