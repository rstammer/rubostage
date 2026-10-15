# A chord as written on a lead sheet ("C#m", "Fmaj7", "A/C#"), turned into
# pitches Sonic Pi can play.
class ChordSymbol
  class Invalid < StandardError; end

  NOTE_NAMES = {"C" => 0, "D" => 2, "E" => 4, "F" => 5, "G" => 7, "A" => 9, "B" => 11}.freeze
  ACCIDENTALS = {"" => 0, "#" => 1, "b" => -1}.freeze

  QUALITIES = {
    "" => [0, 4, 7],
    "m" => [0, 3, 7],
    "min" => [0, 3, 7],
    "-" => [0, 3, 7],
    "5" => [0, 7],
    "6" => [0, 4, 7, 9],
    "m6" => [0, 3, 7, 9],
    "7" => [0, 4, 7, 10],
    "m7" => [0, 3, 7, 10],
    "maj7" => [0, 4, 7, 11],
    "M7" => [0, 4, 7, 11],
    "9" => [0, 4, 7, 10, 14],
    "m9" => [0, 3, 7, 10, 14],
    "maj9" => [0, 4, 7, 11, 14],
    "add9" => [0, 4, 7, 14],
    "sus2" => [0, 2, 7],
    "sus4" => [0, 5, 7],
    "sus" => [0, 5, 7],
    "7sus4" => [0, 5, 7, 10],
    "dim" => [0, 3, 6],
    "dim7" => [0, 3, 6, 9],
    "m7b5" => [0, 3, 6, 10],
    "aug" => [0, 4, 8],
    "+" => [0, 4, 8]
  }.freeze

  # Anything else still counts as a chord if it starts like one; it is then
  # played as the plain triad.
  QUALITY_START = /\A(maj|min|m|M|sus|dim|aug|add|\d|\(|\+|-)/
  PATTERN = /\A([A-G])([#b]?)(.*?)(?:\/([A-G])([#b]?))?\z/

  attr_reader :text, :root, :bass, :intervals

  def self.parse(text)
    match = PATTERN.match(text.to_s.strip)
    raise Invalid, "not a chord: #{text.inspect}" unless match

    root = pitch_class(match[1], match[2])
    bass = match[4] ? pitch_class(match[4], match[5]) : root
    new(text.to_s.strip, root, bass, intervals_for(match[3], text))
  end

  def self.pitch_class(letter, accidental)
    (NOTE_NAMES.fetch(letter) + ACCIDENTALS.fetch(accidental)) % 12
  end

  def self.intervals_for(quality, text)
    return QUALITIES[quality] if QUALITIES.key?(quality)
    raise Invalid, "not a chord: #{text.inspect}" unless QUALITY_START.match?(quality)

    (quality.start_with?("m") && !quality.start_with?("maj")) ? QUALITIES["m"] : QUALITIES[""]
  end

  def initialize(text, root, bass, intervals)
    @text = text
    @root = root
    @bass = bass
    @intervals = intervals
  end

  def pitch_classes
    intervals.map { |i| (root + i) % 12 }.uniq
  end

  # MIDI note between C2 (36) and B2 (47).
  def bass_note
    36 + bass
  end

  # Close voicing around middle C, between A#3 (58) and A4 (69).
  def voicing
    pitch_classes.map { |pc| (60 + pc > 69) ? 48 + pc : 60 + pc }.sort
  end

  def to_s = text
end
