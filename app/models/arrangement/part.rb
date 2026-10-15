# How one section is played: an energy level from 1 to 3, a drum groove, how
# the guitar plays, and sixteen-step patterns with one character per sixteenth
# note. Drums and the guitar rhythm use "x" for a hit; the bass uses "1", "5"
# or "8" for root, fifth or octave; "." is a rest.
#
# The groove names a style from DrumGroove. Older arrangements, and answers
# that spell out kick, snare and hats, play those patterns instead (:custom).
class Arrangement::Part
  STEPS = 16
  BASS_INTERVALS = {"1" => 0, "5" => 7, "8" => 12}.freeze
  GUITARS = %i[power palm strum stabs none].freeze
  MAX_SWING = 0.33

  DEFAULTS = {
    "energy" => 2,
    "kick" => "x.......x.......",
    "snare" => "....x.......x...",
    "hat" => "x.x.x.x.x.x.x.x.",
    "open_hat" => "................",
    "bass" => "1.1.1.1.1.1.1.1.",
    "comp" => "x...x...x...x...",
    "pad" => true
  }.freeze

  DRUMS = %w[kick snare hat open_hat comp].freeze

  attr_reader :energy, :groove, :swing, :fill, :guitar,
    :kick, :snare, :hat, :open_hat, :bass, :comp, :pad

  def self.from_h(data, distorted: false)
    given = data.to_h.compact
    data = DEFAULTS.merge(given)
    groove = groove_for(given)
    new(
      energy: data["energy"].to_i.clamp(1, 3),
      groove: groove,
      swing: given.key?("swing") ? given["swing"].to_f.clamp(0, MAX_SWING) : DrumGroove.default_swing(groove),
      fill: given["fill"] == true,
      guitar: guitar_for(given["guitar"], distorted),
      **DRUMS.to_h { |name| [name.to_sym, hits(name, data[name])] },
      bass: bass_hits(data["bass"]),
      pad: data["pad"] != false
    )
  end

  def self.groove_for(given)
    named = given["groove"].to_s.to_sym
    return named if DrumGroove::NAMES.include?(named)

    (given.key?("kick") || named == :custom) ? :custom : :rock
  end

  def self.guitar_for(name, distorted)
    named = name.to_s.to_sym
    return named if GUITARS.include?(named)

    distorted ? :power : :strum
  end

  def self.hits(name, pattern)
    pattern = checked(name, pattern, /\A[x.]+\z/)
    (0...pattern.length).select { |i| pattern[i] == "x" }
  end

  def self.bass_hits(pattern)
    pattern = checked("bass", pattern, /\A[158.]+\z/)
    pattern.each_char.with_index.filter_map { |char, i| [i, BASS_INTERVALS[char]] if BASS_INTERVALS.key?(char) }
  end

  def self.checked(name, pattern, allowed)
    pattern = pattern.to_s
    unless pattern.length == STEPS && allowed.match?(pattern)
      raise Arrangement::Invalid, "#{name} needs #{STEPS} steps of #{allowed.source}, got #{pattern.inspect}"
    end

    pattern
  end

  def initialize(energy:, groove:, swing:, fill:, guitar:, kick:, snare:, hat:, open_hat:, bass:, comp:, pad:)
    @energy = energy
    @groove = groove
    @swing = swing
    @fill = fill
    @guitar = guitar
    @kick = kick
    @snare = snare
    @hat = hat
    @open_hat = open_hat
    @bass = bass
    @comp = comp
    @pad = pad
  end

  # Drum hits as [step, velocity] for each voice, from the style or, for
  # :custom, from the spelled-out patterns at full velocity.
  def drum_hits
    return DrumGroove.fetch(groove) unless groove == :custom

    {
      kick: kick.map { |s| [s, 1.0] }, snare: snare.map { |s| [s, 1.0] },
      hat: hat.map { |s| [s, (s % 4).zero? ? 0.8 : 0.5] }, open_hat: open_hat.map { |s| [s, 0.6] }
    }
  end

  def to_h
    {
      "energy" => energy, "groove" => groove.to_s, "swing" => swing, "fill" => fill, "guitar" => guitar.to_s,
      **DRUMS.to_h { |name| [name, pattern_for(public_send(name))] },
      "bass" => bass_pattern,
      "pad" => pad
    }
  end

  private

  def pattern_for(hits)
    (0...STEPS).map { |i| hits.include?(i) ? "x" : "." }.join
  end

  def bass_pattern
    by_step = bass.to_h
    (0...STEPS).map { |i| BASS_INTERVALS.key(by_step[i]) || "." }.join
  end
end
