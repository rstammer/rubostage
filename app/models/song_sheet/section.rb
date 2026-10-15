# One section of a lead sheet: a name and its bars. A bar holds one chord, or
# two that split it in half.
class SongSheet::Section
  attr_reader :name, :bars

  def self.from_h(data)
    data = data.to_h.stringify_keys
    bars = Array(data["bars"]).map do |bar|
      chords = Array(bar)
      unless (1..2).cover?(chords.size)
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

    @name = name
    @bars = bars
  end

  def to_h
    {"name" => name, "bars" => bars.map { |bar| bar.map(&:to_s) }}
  end
end
