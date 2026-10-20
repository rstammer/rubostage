# starlight (Muse) — play-along, live version
#
# A bed to play guitar and sing over, built the same way as mcblinded's
# songs/traveller/live.rb: live_loops that ask get[:section] at the top of each
# pass, so a switch lands on the next four-bar boundary and never cuts in.
#
# Switch from a second terminal:
#
#   bin/play -e 'set :section, :verse'
#   bin/play -e 'set :section, :intro'
#   bin/play -e 'set :section, :bridge'
#
# 122 BPM, B major. Intro, verse and B section share I - ii - vi - IV
# (B - C#m - G#m - E), one bar each. THE BRIDGE IS NOT CONFIRMED: its
# G#m - E - B - F# is a guess at the relative-minor section and needs Robin's
# ear. See NOTES.md.
#
# The keys line is our own figure over the chords, not the record's piano riff.
#
# use_bpm sits above the live_loops: it is thread-local, and loops inherit it
# when they are created.

use_bpm 122

# How far the snare sits behind the beat, in beats (0.04 is about 20 ms).
behind = 0.04

# [bass root, voicing], one bar each
main_harmony = [
  [:b1, [:b3, :ds4, :fs4]],
  [:cs2, [:cs4, :e4, :gs4]],
  [:gs1, [:b3, :ds4, :gs4]],
  [:e1, [:b3, :e4, :gs4]]
]

# All sections are exactly four bars, so the voices stay aligned no matter
# when a switch lands. Drum slots are sixteenths within one bar.
sections = {
  intro: {
    harmony: main_harmony,
    kick_at: [0, 8, 10],
    snare_at: [4, 12],
    clap: true,
    hat_every: 2,
    bass_every: 2,
    push: false,
    keys: true,
    arp: false
  },
  verse: {
    harmony: main_harmony,
    kick_at: [0, 6],
    snare_at: [8],
    clap: false,
    hat_every: 2,
    bass_every: 4,
    push: false,
    keys: false,
    arp: false
  },
  bridge: {
    harmony: [
      [:gs1, [:b3, :ds4, :gs4]],
      [:e1, [:b3, :e4, :gs4]],
      [:b1, [:b3, :ds4, :fs4]],
      [:fs1, [:as3, :cs4, :fs4]]
    ],
    kick_at: [0, 4, 8, 12],
    snare_at: [4, 12],
    clap: false,
    hat_every: 1,
    bass_every: 2,
    push: true,
    keys: false,
    arp: true
  }
}

set :section, :intro

# Four clicks lead in.
4.times do
  sample :drum_cymbal_closed, amp: 0.8
  sleep 1
end

live_loop :drums, sync: :bar do
  part = sections[get[:section]]
  64.times do |slot|
    step = slot % 16
    sample :drum_bass_hard, amp: 0.7 if part[:kick_at].include?(step)
    if part[:snare_at].include?(step)
      time_warp behind do
        sample :drum_snare_hard, amp: 0.65
        sample :perc_snap, amp: 0.4 if part[:clap]
      end
    end
    if step % part[:hat_every] == 0
      sample :drum_cymbal_closed, amp: (step % 4 == 0) ? 0.3 : 0.15
    end
    sleep 0.25
  end
end

# Distorted and driving. In the bridge the second and fourth bar jump to the
# next root on the last eighth, the quick change on the "and" of four.
live_loop :bass, sync: :bar do
  part = sections[get[:section]]
  bars = part[:harmony]
  hits = 16 / part[:bass_every]
  use_synth :fm
  with_fx :distortion, distort: 0.6, mix: 0.7 do
    with_fx :lpf, cutoff: 90 do
      bars.each_with_index do |(root, _voicing), bar|
        following = bars[(bar + 1) % bars.length][0]
        hits.times do |hit|
          bass_note = (part[:push] && bar.odd? && hit == hits - 1) ? following : root
          play bass_note, release: part[:bass_every] * 0.22, amp: 0.5,
            divisor: 1, depth: 1.5
          sleep part[:bass_every] * 0.25
        end
      end
    end
  end
end

live_loop :pad, sync: :bar do
  part = sections[get[:section]]
  use_synth :hollow
  with_fx :reverb, room: 0.8, mix: 0.4 do
    part[:harmony].each do |_root, voicing|
      play voicing, attack: 0.3, release: 3.8, amp: 0.3, cutoff: 90
      sleep 4
    end
  end
end

# Our own eighth-note figure through the chord tones, doubled faintly by a bell
# an octave up.
live_loop :keys, sync: :bar do
  part = sections[get[:section]]
  if part[:keys]
    with_fx :reverb, room: 0.7, mix: 0.35 do
      part[:harmony].each do |_root, voicing|
        upper = voicing.map { |n| note(n) + 12 }
        [0, 1, 2, 1, 2, 1, 0, 1].each do |idx|
          synth :piano, note: upper[idx], amp: 0.5, hard: 0.4
          synth :pretty_bell, note: upper[idx] + 12, amp: 0.08, release: 0.3
          sleep 0.5
        end
      end
    end
  else
    sleep 16
  end
end

# Sixteenth-note arpeggio for the bridge, opening up across each bar.
live_loop :arp, sync: :bar do
  part = sections[get[:section]]
  if part[:arp]
    part[:harmony].each do |_root, voicing|
      stack = voicing.map { |n| note(n) + 12 } + [note(voicing[0]) + 24]
      16.times do |i|
        synth :saw, note: stack[i % stack.length], release: 0.15, amp: 0.15,
          cutoff: 80 + i * 2
        sleep 0.25
      end
    end
  else
    sleep 16
  end
end

# Defined last, so every voice above is already waiting on :bar when the first
# cue fires. Defined first, they missed it and the first four bars were silent.
live_loop :clock do
  cue :bar
  sleep 16
end
