# A guitar riff written as ASCII tab, one character per sixteenth note:
#
#   e|----------------|
#   B|----------------|
#   G|----------------|
#   D|--2-2-----------|
#   A|--2-2---0-------|
#   E|--0-0---------3-|
#
# The top line is the high string. Bars are sixteen characters between bar
# lines; a longer riff continues in further bars or in a second block of six
# lines. A fret number is a note, "x" a muted dead note, "-" lets the string
# ring. Bends, slides and hammer-ons are read as plain frets.
#
# The fingering comes from whoever writes the tab: it is played as written,
# never worked out from pitches.
#
# A bass tab has four lines (G D A E). Its strings are the guitar's lowest
# four an octave down, so every tuning works for both.
class Tab
  class Invalid < StandardError; end

  TUNINGS = {
    "standard" => [40, 45, 50, 55, 59, 64],
    "drop_d" => [38, 45, 50, 55, 59, 64],
    "half_down" => [39, 44, 49, 54, 58, 63],
    "d_standard" => [38, 43, 48, 53, 57, 62]
  }.freeze

  STRINGS = 6
  BASS_STRINGS = 4
  STEPS_PER_BAR = 16
  UNKNOWN = %r{[^0-9x\-hpbr/\\~v]}
  LABEL = /\A\s*([A-Ga-g][#b]?)?\s*\|/

  NOTE_NAMES = %w[C Db D Eb E F Gb G Ab A Bb B].freeze

  # The string names a tab in this tuning starts its lines with.
  def self.labels(tuning, bass: false)
    names = open_strings(tuning, bass).reverse.map { |pitch| NOTE_NAMES[pitch % 12] }
    bass ? names : [names.first.downcase, *names.drop(1)]
  end

  # Low string first.
  def self.open_strings(tuning, bass)
    guitar = TUNINGS.fetch(tuning.to_s) { raise Invalid, "unknown tuning #{tuning.inspect}" }
    bass ? guitar.first(BASS_STRINGS).map { |pitch| pitch - 12 } : guitar
  end

  # Notes as [step, pitch, steps held]; a dead note is held for 0 steps.
  attr_reader :steps, :notes

  def self.parse(text, tuning: "standard", bass: false)
    open_strings = open_strings(tuning, bass)
    count = open_strings.size
    lines = text.to_s.lines.map(&:strip).reject(&:empty?)
    return nil if lines.empty?

    unless (lines.size % count).zero?
      raise Invalid, "a tab needs #{(count == STRINGS) ? "six" : "four"} lines per block, one per string, got #{lines.size}"
    end

    strings = Array.new(count) { +"" }
    lines.each_slice(count) do |block|
      read_block(block).each_with_index { |steps, i| strings[i] << steps }
    end
    new(strings, open_strings.reverse)
  end

  # The lines of one block, as the steps of each string with labels and
  # bar lines taken out.
  def self.read_block(block)
    strings = block.each_with_index.map do |line, i|
      label = line[LABEL, 1] || "line #{i + 1}"
      bars = line.sub(LABEL, "").split("|").reject(&:empty?)
      bars.each_with_index do |bar, n|
        next if bar.length == STEPS_PER_BAR

        raise Invalid, "#{label} string, bar #{n + 1}: #{bar.length} steps, needs #{STEPS_PER_BAR}"
      end
      [label, bars]
    end
    raise Invalid, "the strings have different numbers of bars" if strings.map { |_, bars| bars.size }.uniq.size > 1

    strings.map do |label, bars|
      unknown = bars.join[UNKNOWN]
      raise Invalid, "unknown sign #{unknown.inspect} on the #{label} string" if unknown

      bars.join
    end
  end

  def initialize(strings, open_strings)
    @steps = strings.first.length
    @notes = strings.each_with_index.flat_map { |steps, i| string_notes(steps, open_strings[i]) }
      .sort_by { |step, pitch, _held| [step, pitch] }
  end

  private

  def string_notes(steps, open_string)
    hits = []
    i = 0
    while i < steps.length
      char = steps[i]
      if char == "x"
        hits << [i, open_string, :dead]
      elsif char.match?(/\d/)
        digits = (steps[i, 2].match?(/\A\d\d\z/) && steps[i, 2].to_i <= 24) ? 2 : 1
        hits << [i, open_string + steps[i, digits].to_i, :fret]
        i += digits - 1
      end
      i += 1
    end
    hits.each_with_index.map do |(step, pitch, kind), n|
      ends = hits[n + 1]&.first || @steps
      [step, pitch, (kind == :dead) ? 0 : ends - step]
    end
  end
end
