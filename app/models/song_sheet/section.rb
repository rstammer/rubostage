# One section of a lead sheet: a name and its bars. A bar holds one chord, or
# two that split it in half, or none: an empty bar (written "%" on a chart)
# holds the chord before it for another bar.
class SongSheet::Section
  HOLD = "%"

  attr_reader :name, :bars

  def self.from_h(data)
    data = data.to_h.stringify_keys
    bars = Array(data["bars"]).map do |bar|
      chords = Array(bar) - [HOLD]
      unless (0..2).cover?(chords.size)
        raise SongSheet::Invalid, "a bar needs one or two chords, got #{chords.inspect}"
      end

      chords.map { |text| ChordSymbol.parse(text) }
    end
    new(data["name"].to_s, bars)
  rescue ChordSymbol::Invalid => e
    raise SongSheet::Invalid, e.message
  end

  def initialize(name, bars)
    raise SongSheet::Invalid, "a section needs a name" if name.blank?
    raise SongSheet::Invalid, "section #{name} has no bars" if bars.empty?
    raise SongSheet::Invalid, "section #{name} starts with an empty bar, there is no chord to hold" if bars.first.empty?

    @name = name
    @bars = bars
  end

  # The chords as they sound, each with its beats: a split bar gives two
  # beats to each chord, an empty bar four more to the chord before it.
  def steps
    bars.each_with_object([]) do |bar, steps|
      if bar.empty?
        steps.last[1] += 4
      else
        bar.each { |chord| steps << [chord, 4 / bar.size] }
      end
    end
  end

  # "Am | % | F G", the way a chart writes it.
  def chart
    bars.map { |bar| bar.empty? ? HOLD : bar.join(" ") }.join(" | ")
  end

  def to_h
    {"name" => name, "bars" => bars.map { |bar| bar.map(&:to_s) }}
  end
end
