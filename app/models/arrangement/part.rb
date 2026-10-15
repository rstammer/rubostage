# How one section is played: an energy level from 1 to 3 and sixteen-step
# patterns, one character per sixteenth note. Drums use "x" for a hit; the
# bass uses "1", "5" or "8" for root, fifth or octave; "." is a rest.
class Arrangement::Part
  STEPS = 16
  BASS_INTERVALS = {"1" => 0, "5" => 7, "8" => 12}.freeze

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

  attr_reader :energy, :kick, :snare, :hat, :open_hat, :bass, :comp, :pad

  def self.from_h(data)
    data = DEFAULTS.merge(data.to_h.compact)
    new(
      energy: data["energy"].to_i.clamp(1, 3),
      **DRUMS.to_h { |name| [name.to_sym, hits(name, data[name])] },
      bass: bass_hits(data["bass"]),
      pad: data["pad"] != false
    )
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

  def initialize(energy:, kick:, snare:, hat:, open_hat:, bass:, comp:, pad:)
    @energy = energy
    @kick = kick
    @snare = snare
    @hat = hat
    @open_hat = open_hat
    @bass = bass
    @comp = comp
    @pad = pad
  end

  def to_h
    {
      "energy" => energy,
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
