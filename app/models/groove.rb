# A play-along that walks through the sheet's form section by section and
# closes on the key's chord. Without an arrangement it is the plain groove of
# stage one: drums, bass, a strummed comp and a pad. With one, every section
# gets its own patterns, sounds and energy.
#
# A conductor loop decides which section comes next and cues it; every voice
# syncs to that cue and plays exactly that section. Commands from the stage
# (repeat, next, jump, end) arrive as `set :stage_cmd` and are only read at a
# section boundary, so the voices never fall out of step. The same split lets
# stage two swap the voices while the conductor keeps its place in the form.
class Groove
  # With a song id, the groove reports every chord change to the stage over
  # OSC, so the lead sheet can follow along.
  def initialize(sheet, song_id: nil, osc_port: nil, arrangement: nil)
    @sheet = sheet
    @song_id = song_id
    @osc_port = osc_port
    @arrangement = arrangement
  end

  # One entry per chord in playing order.
  def timeline
    @sheet.played_sections.flat_map { |section| section_steps(section) }
  end

  # The whole song: data, lead-in, voices and conductor.
  def code
    [header, data_block, start_block, voices_block, conductor_block].join("\n")
  end

  # Only data and voices. Sent while the song plays, it replaces each voice at
  # its next section without touching the conductor.
  def voices_code
    [header, data_block, voices_block].join("\n")
  end

  private

  def header
    <<~RUBY
      # #{@sheet.title} — #{@sheet.artist}
      #
      # #{@arrangement ? "Arranged" : "A groove"} from the mcblinded stage. Key #{@sheet.key}, #{@sheet.bpm} BPM.
      # Form: #{@sheet.form.join(" – ")}.
      #
      # use_bpm sits above the live_loops: it is thread-local, and loops inherit
      # it when they are created.

      use_bpm #{@sheet.bpm}
    RUBY
  end

  def data_block
    block = <<~RUBY
      # Each section once: [bass note, voicing, beats] per chord
      sections = [
      #{sections_literal}
      ]

      # The order they are played in, as indexes into sections
      form = #{form_indexes.inspect}

      # Where each form position starts, counted in chords, for the stage
      offsets = #{offsets.inspect}

      # The closing chord: [bass note, voicing]
      final = [#{final_chord.bass_note}, #{final_chord.voicing.inspect}]
    RUBY
    return block unless @arrangement

    block + <<~RUBY

      # Per section: which chord sounds on each beat, as an index into its chords
      beats_at = #{beat_maps.inspect}

      # Per section: energy and sixteen-step patterns (step numbers within a bar)
      parts = [
      #{parts_literal}
      ]

      # Loudness per energy level
      levels = [0, 0.6, 0.8, 1.0]
    RUBY
  end

  def start_block
    <<~RUBY
      set :stage_next, 0
      set :stage_seen, (get[:stage_cmd] || [0])[0]

      # Four clicks lead in.
      4.times do
        sample :drum_cymbal_closed, amp: 0.8
        sleep 1
      end
    RUBY
  end

  def voices_block
    @arrangement ? arranged_voices : plain_voices
  end

  def plain_voices
    <<~RUBY
      live_loop :drums do
        pos = sync(:section)[0]
        if pos < 0
          sample :drum_cymbal_open, amp: 0.6
          sample :drum_bass_hard, amp: 0.9
          stop
        end
        sections[form[pos]].sum { |step| step[2] }.times do |count|
          sample :drum_bass_hard, amp: 0.7 if count.even?
          sample :drum_snare_hard, amp: 0.6 if count.odd?
          sample :drum_cymbal_closed, amp: 0.25
          sleep 0.5
          sample :drum_cymbal_closed, amp: 0.12
          sleep 0.5
        end
      end

      live_loop :bass do
        pos = sync(:section)[0]
        use_synth :fm
        if pos < 0
          play final[0], release: 3, amp: 0.6, divisor: 1, depth: 1.2
          stop
        end
        with_fx :lpf, cutoff: 90 do
          sections[form[pos]].each do |root, _voicing, beats|
            (beats * 2).times do
              play root, release: 0.4, amp: 0.55, divisor: 1, depth: 1.2
              sleep 0.5
            end
          end
        end
      end

      live_loop :comp do
        pos = sync(:section)[0]
        use_synth :pluck
        if pos < 0
          final[1].each { |n| play n, amp: 0.4, coef: 0.4, release: 3 }
          stop
        end
        with_fx :reverb, room: 0.5, mix: 0.25 do
          sections[form[pos]].each do |_root, voicing, beats|
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

      live_loop :pad do
        pos = sync(:section)[0]
        use_synth :hollow
        if pos < 0
          play final[1], attack: 0.1, release: 4, amp: 0.3, cutoff: 90
          stop
        end
        with_fx :reverb, room: 0.8, mix: 0.4 do
          sections[form[pos]].each do |_root, voicing, beats|
            play voicing, attack: 0.2, release: beats * 0.95, amp: 0.3, cutoff: 90
            sleep beats
          end
        end
      end
    RUBY
  end

  def arranged_voices
    sounds = @arrangement.sounds
    comp_open = sounds[:distorted] ? "with_fx :distortion, distort: 0.6 do" : "with_fx :reverb, room: 0.5, mix: 0.25 do"
    <<~RUBY
      live_loop :drums do
        pos = sync(:section)[0]
        if pos < 0
          sample :drum_splash_hard, amp: 0.6
          sample :drum_bass_hard, amp: 0.9
          stop
        end
        part = parts[form[pos]]
        level = levels[part[:energy]]
        sample :drum_splash_hard, amp: 0.4 * level if part[:energy] == 3
        (beats_at[form[pos]].length * 4).times do |slot|
          step = slot % 16
          sample :drum_bass_hard, amp: 0.8 * level if part[:kick].include?(step)
          sample :drum_snare_hard, amp: 0.7 * level if part[:snare].include?(step)
          if part[:open_hat].include?(step)
            sample :drum_cymbal_open, amp: 0.3 * level, sustain: 0.1, release: 0.2
          elsif part[:hat].include?(step)
            sample :drum_cymbal_closed, amp: ((step % 4 == 0) ? 0.3 : 0.16) * level
          end
          sleep 0.25
        end
      end

      live_loop :bass do
        pos = sync(:section)[0]
        use_synth :#{sounds[:bass]}
        if pos < 0
          play final[0], release: 3, amp: 0.6
          stop
        end
        part = parts[form[pos]]
        chords = sections[form[pos]]
        at = beats_at[form[pos]]
        with_fx :lpf, cutoff: 95 do
          (at.length * 4).times do |slot|
            hit = part[:bass].find { |s, _interval| s == slot % 16 }
            play chords[at[slot / 4]][0] + hit[1], release: 0.3, amp: 0.55 * levels[part[:energy]] if hit
            sleep 0.25
          end
        end
      end

      live_loop :comp do
        pos = sync(:section)[0]
        use_synth :#{sounds[:comp]}
        if pos < 0
          play final[1], amp: 0.35, release: 3
          stop
        end
        part = parts[form[pos]]
        chords = sections[form[pos]]
        at = beats_at[form[pos]]
        #{comp_open}
          (at.length * 4).times do |slot|
            if part[:comp].include?(slot % 16)
              play chords[at[slot / 4]][1], release: 0.25, amp: 0.3 * levels[part[:energy]]
            end
            sleep 0.25
          end
        end
      end

      live_loop :pad do
        pos = sync(:section)[0]
        use_synth :#{sounds[:pad]}
        if pos < 0
          play final[1], attack: 0.1, release: 4, amp: 0.25, cutoff: 90
          stop
        end
        part = parts[form[pos]]
        with_fx :reverb, room: 0.8, mix: 0.4 do
          sections[form[pos]].each do |_root, voicing, beats|
            play voicing, attack: 0.2, release: beats * 0.95, amp: 0.25 * levels[part[:energy]], cutoff: 90 if part[:pad]
            sleep beats
          end
        end
      end
    RUBY
  end

  def conductor_block
    <<~RUBY
      # Decides what comes next and cues it. Defined last, so every voice above
      # is already waiting on :section when the first cue fires.
      live_loop :conductor do
        pos = get[:stage_next]
        cue :section, pos
        #{report_ending}
        stop if pos < 0
        #{report_steps}
        following = pos + 1
        cmd = get[:stage_cmd]
        if cmd && cmd[0] != get[:stage_seen]
          set :stage_seen, cmd[0]
          following = pos if cmd[1] == :repeat
          following = cmd[2] if cmd[1] == :jump
          following = -1 if cmd[1] == :end
        end
        following = -1 if following >= form.length
        set :stage_next, following
      end
    RUBY
  end

  def section_steps(section)
    section.bars.flat_map do |bar|
      bar.map do |chord|
        {section: section.name, chord: chord.to_s, bass: chord.bass_note,
         voicing: chord.voicing, beats: 4 / bar.size}
      end
    end
  end

  def sections_literal
    @sheet.sections.map do |section|
      rows = section_steps(section).map do |s|
        "    [#{s[:bass]}, #{s[:voicing].inspect}, #{s[:beats]}], # #{s[:section]}: #{s[:chord]}"
      end
      "  [\n#{rows.join("\n")}\n  ]"
    end.join(",\n")
  end

  # For each section, the chord index sounding on each of its beats.
  def beat_maps
    @sheet.sections.map do |section|
      section_steps(section).each_with_index.flat_map { |step, i| [i] * step[:beats] }
    end
  end

  def parts_literal
    @sheet.sections.map do |section|
      part = @arrangement.section(section.name)
      "  {energy: #{part.energy}, kick: #{part.kick.inspect}, snare: #{part.snare.inspect}, " \
        "hat: #{part.hat.inspect}, open_hat: #{part.open_hat.inspect}, bass: #{part.bass.inspect}, " \
        "comp: #{part.comp.inspect}, pad: #{part.pad}}, # #{section.name}"
    end.join("\n")
  end

  def form_indexes
    @sheet.played_sections.map { |section| @sheet.sections.index(section) }
  end

  def offsets
    @sheet.played_sections.each_with_object([0]) { |section, acc| acc << acc.last + section_steps(section).size }[0...-1]
  end

  # The key's chord; when the key is not written as a chord, the first chord
  # of the last section.
  def final_chord
    ChordSymbol.parse(@sheet.key)
  rescue ChordSymbol::Invalid
    @sheet.played_sections.last.bars.first.first
  end

  def report_ending
    return "" unless @song_id

    <<~LINES.chomp
      use_osc "127.0.0.1", #{@osc_port}
        osc "/stage/step", #{@song_id}, -1 if pos < 0
    LINES
  end

  def report_steps
    sleeps = "sections[form[pos]].each_with_index do |(_root, _voicing, beats), index|\n"
    sleeps += "    osc \"/stage/step\", #{@song_id}, offsets[pos] + index\n" if @song_id
    sleeps + "    sleep beats\n  end"
  end
end
