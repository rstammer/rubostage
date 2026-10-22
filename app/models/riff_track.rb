# The riffs written for a song: a tab per section, the tuning they are
# fretted in, and whether they play crunchy or clean. Groove turns them into
# a voice of its own, on top of whatever the arrangement plays.
class RiffTrack
  TONES = %w[crunch clean].freeze

  attr_reader :tuning, :tone, :tabs

  def self.from_h(data)
    data = data.to_h
    tuning = data["tuning"].to_s
    tone = data["tone"].to_s
    new(
      tuning: Tab::TUNINGS.key?(tuning) ? tuning : Tab::TUNINGS.keys.first,
      tone: TONES.include?(tone) ? tone : TONES.first,
      tabs: data["tabs"].to_h.reject { |_name, text| text.to_s.strip.empty? }
    )
  end

  def initialize(tuning:, tone:, tabs:)
    @tuning = tuning
    @tone = tone
    @tabs = tabs
  end

  def tab(name)
    Tab.parse(tabs[name], tuning: tuning)
  rescue Tab::Invalid => e
    raise Tab::Invalid, "#{name}: #{e.message}"
  end

  def empty? = tabs.empty?

  def validate!
    tabs.each_key { |name| tab(name) }
    self
  end

  def to_h
    {"tuning" => tuning, "tone" => tone, "tabs" => tabs}
  end
end
