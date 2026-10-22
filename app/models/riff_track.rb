# The riffs written for a song: per section a guitar tab, a bass tab or
# both, the tuning they are fretted in, and whether the guitar plays crunchy
# or clean. Groove turns each into a voice of its own; the guitar's sits on
# top of the arrangement, the bass's takes the place of the bass line.
class RiffTrack
  TONES = %w[crunch clean].freeze

  attr_reader :tuning, :tone, :tabs, :bass_tabs

  def self.from_h(data)
    data = data.to_h
    tuning = data["tuning"].to_s
    tone = data["tone"].to_s
    new(
      tuning: Tab::TUNINGS.key?(tuning) ? tuning : Tab::TUNINGS.keys.first,
      tone: TONES.include?(tone) ? tone : TONES.first,
      tabs: written(data["tabs"]), bass_tabs: written(data["bass_tabs"])
    )
  end

  def self.written(tabs)
    tabs.to_h.reject { |_name, text| text.to_s.strip.empty? }
  end

  def initialize(tuning:, tone:, tabs:, bass_tabs: {})
    @tuning = tuning
    @tone = tone
    @tabs = tabs
    @bass_tabs = bass_tabs
  end

  def tab(name)
    Tab.parse(tabs[name], tuning: tuning)
  rescue Tab::Invalid => e
    raise Tab::Invalid, "#{name}: #{e.message}"
  end

  def bass_tab(name)
    Tab.parse(bass_tabs[name], tuning: tuning, bass: true)
  rescue Tab::Invalid => e
    raise Tab::Invalid, "#{name} (Bass): #{e.message}"
  end

  def empty? = tabs.empty? && bass_tabs.empty?

  def validate!
    tabs.each_key { |name| tab(name) }
    bass_tabs.each_key { |name| bass_tab(name) }
    self
  end

  def to_h
    {"tuning" => tuning, "tone" => tone, "tabs" => tabs, "bass_tabs" => bass_tabs}
  end
end
