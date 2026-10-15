# Stage one of a play-along: a plain groove that plays the sheet's whole form
# and loops it. Drums, bass, a strummed comp and a pad — enough to carry on its
# own, nothing that needs more than the chords.
class Groove
  def initialize(sheet)
    @sheet = sheet
  end

  # One entry per chord in playing order.
  def timeline
    @sheet.played_sections.flat_map do |section|
      section.bars.flat_map do |bar|
        bar.map do |chord|
          {section: section.name, chord: chord.to_s, bass: chord.bass_note,
           voicing: chord.voicing, beats: 4 / bar.size}
        end
      end
    end
  end

  def total_beats
    timeline.sum { |step| step[:beats] }
  end

  def code
    <<~RUBY
      # #{@sheet.title} — #{@sheet.artist}
      #
      # A first groove from the mcblinded stage: the whole form, then again.
      # Key #{@sheet.key}, #{@sheet.bpm} BPM. Form: #{@sheet.form.join(" – ")}.
      #
      # use_bpm sits above the live_loops: it is thread-local, and loops inherit
      # it when they are created.

      use_bpm #{@sheet.bpm}

      # [bass note, voicing, beats], one entry per chord
      steps = [
      #{steps_literal}
      ]

      # Four clicks lead in.
      4.times do
        sample :drum_cymbal_closed, amp: 0.8
        sleep 1
      end

      live_loop :drums, sync: :bar do
        #{total_beats}.times do |count|
          sample :drum_bass_hard, amp: 0.7 if count.even?
          sample :drum_snare_hard, amp: 0.6 if count.odd?
          sample :drum_cymbal_closed, amp: 0.25
          sleep 0.5
          sample :drum_cymbal_closed, amp: 0.12
          sleep 0.5
        end
      end

      live_loop :bass, sync: :bar do
        use_synth :fm
        with_fx :lpf, cutoff: 90 do
          steps.each do |root, _voicing, beats|
            (beats * 2).times do
              play root, release: 0.4, amp: 0.55, divisor: 1, depth: 1.2
              sleep 0.5
            end
          end
        end
      end

      live_loop :comp, sync: :bar do
        use_synth :pluck
        with_fx :reverb, room: 0.5, mix: 0.25 do
          steps.each do |_root, voicing, beats|
            beats.times do
              voicing.each do |n|
                play n, amp: 0.35, coef: 0.4
                sleep 0.01
              end
              sleep 1 - 0.01 * voicing.length
            end
          end
        end
      end

      live_loop :pad, sync: :bar do
        use_synth :hollow
        with_fx :reverb, room: 0.8, mix: 0.4 do
          steps.each do |_root, voicing, beats|
            play voicing, attack: 0.2, release: beats * 0.95, amp: 0.3, cutoff: 90
            sleep beats
          end
        end
      end

      # Defined last, so every voice above is already waiting on :bar when the
      # first cue fires.
      live_loop :clock do
        cue :bar
        sleep #{total_beats}
      end
    RUBY
  end

  private

  def steps_literal
    timeline.map { |s| "  [#{s[:bass]}, #{s[:voicing].inspect}, #{s[:beats]}], # #{s[:section]}: #{s[:chord]}" }
      .join("\n")
  end
end
