# Stage two of a play-along: how the band plays each section. Sounds come
# from a fixed list and patterns are sixteen-step strings, so whatever comes
# back, Groove can always turn it into code that runs and stays in step.
class Arrangement
  class Invalid < StandardError; end

  SOUNDS = {
    bass: %i[fm tb303 subpulse pulse],
    comp: %i[pluck piano pulse blade tri],
    pad: %i[hollow dark_ambience blade saw]
  }.freeze

  attr_reader :sounds, :parts

  def self.parse(text, sheet)
    start = text.index("{")
    finish = text.rindex("}")
    raise Invalid, "no JSON in the answer" unless start && finish && finish > start

    from_h(JSON.parse(text[start..finish]), sheet)
  rescue JSON::ParserError => e
    raise Invalid, "unreadable JSON: #{e.message}"
  end

  def self.from_h(data, sheet)
    data = data.to_h
    given = data["sounds"].to_h
    sounds = SOUNDS.to_h do |voice, allowed|
      wished = given[voice.to_s].to_s.to_sym
      [voice, allowed.include?(wished) ? wished : allowed.first]
    end
    sounds[:distorted] = given["distorted"] == true

    sections = data["sections"].to_h
    parts = sheet.sections.to_h { |s| [s.name, Arrangement::Part.from_h(sections[s.name])] }
    new(sounds, parts)
  end

  def initialize(sounds, parts)
    @sounds = sounds
    @parts = parts
  end

  def section(name) = parts.fetch(name)

  def to_h
    {
      "sounds" => sounds.transform_keys(&:to_s).transform_values { |v| v.is_a?(Symbol) ? v.to_s : v },
      "sections" => parts.transform_values(&:to_h)
    }
  end
end
