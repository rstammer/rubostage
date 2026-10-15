# What the lead sheet says about a song: key, tempo, sections with their
# chords bar by bar, and the order the sections are played in. Deliberately
# no lyrics and no melody — the singer brings those.
class SongSheet
  class Invalid < StandardError; end

  BPM_RANGE = (40..240)

  attr_reader :title, :artist, :key, :bpm, :sections, :form

  # Reads the sheet out of an answer that may wrap the JSON in prose or a
  # code fence.
  def self.parse(text)
    start = text.index("{")
    finish = text.rindex("}")
    raise Invalid, "no JSON in the answer" unless start && finish && finish > start

    from_h(JSON.parse(text[start..finish]))
  rescue JSON::ParserError => e
    raise Invalid, "unreadable JSON: #{e.message}"
  end

  def self.from_h(data)
    data = data.to_h.stringify_keys
    sections = Array(data["sections"]).map { |s| SongSheet::Section.from_h(s) }
    form = Array(data["form"]).map(&:to_s)
    form = sections.map(&:name) if form.empty?
    new(
      title: data["title"].to_s, artist: data["artist"].to_s, key: data["key"].to_s,
      bpm: data["bpm"], sections: sections, form: form
    )
  end

  def initialize(title:, artist:, key:, bpm:, sections:, form:)
    @title = title
    @artist = artist
    @key = key
    @bpm = bpm
    @sections = sections
    @form = form
    validate!
  end

  def section(name)
    sections.find { |s| s.name == name }
  end

  def played_sections
    form.map { |name| section(name) }
  end

  def to_h
    {
      "title" => title, "artist" => artist, "key" => key, "bpm" => bpm,
      "sections" => sections.map(&:to_h), "form" => form
    }
  end

  private

  def validate!
    raise Invalid, "bpm must be a whole number in #{BPM_RANGE}" unless bpm.is_a?(Integer) && BPM_RANGE.cover?(bpm)
    raise Invalid, "no sections" if sections.empty?

    missing = form.reject { |name| section(name) }
    raise Invalid, "form names missing sections: #{missing.join(", ")}" if missing.any?
  end
end
