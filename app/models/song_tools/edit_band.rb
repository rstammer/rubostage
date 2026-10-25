# Changes how the band plays: the sounds, and per section its energy, drum
# groove, guitar part and sixteen-step patterns. Only what is given changes.
class SongTools::EditBand < SongTools::Tool
  PATTERN = "16 characters, one per sixteenth note"

  define(
    name: "edit_band",
    description: "Change how the band plays the song. Give only what changes. Patterns are #{PATTERN}: " \
      "drums and comp use \"x\" or \".\", bass uses \"1\" (root), \"5\" (fifth), \"8\" (octave) or \".\". " \
      "Named grooves bring their own drums; to spell out kick, snare and hats, set groove to \"custom\". " \
      "The busker can undo every change.",
    input_schema: {
      type: "object",
      properties: {
        summary: {type: "string", description: "What the change does, in a few German words, for the undo button."},
        sounds: {
          type: "object",
          properties: {
            bass: {type: "string", enum: Arrangement::SOUNDS[:bass].map(&:to_s)},
            comp: {type: "string", enum: Arrangement::SOUNDS[:comp].map(&:to_s), description: "The sound of guitar stabs."},
            pad: {type: "string", enum: Arrangement::SOUNDS[:pad].map(&:to_s)},
            distorted: {type: "boolean"}
          }
        },
        sections: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: {type: "string"},
              energy: {type: "integer", minimum: 1, maximum: 3},
              groove: {type: "string", enum: (DrumGroove::NAMES + [:custom]).map(&:to_s)},
              swing: {type: "number", minimum: 0, maximum: Arrangement::Part::MAX_SWING},
              fill: {type: "boolean", description: "Tom fill at the end of a sixteen-beat phrase."},
              guitar: {type: "string", enum: Arrangement::Part::GUITARS.map(&:to_s)},
              pad: {type: "boolean"},
              **%w[kick snare hat open_hat comp bass].to_h { |name| [name.to_sym, {type: "string", description: PATTERN}] }
            },
            required: ["name"]
          }
        }
      },
      required: ["summary"]
    }
  )

  def call(song, args)
    sheet = song.lead_sheet
    data = (song.arrangement || {}).deep_dup
    sounds = data["sounds"].to_h.merge(checked_sounds(args["sounds"].to_h))
    sections = data["sections"].to_h
    Array(args["sections"]).each do |section|
      name = section["name"]
      raise SongTools::Error, "no section #{name.inspect}, the song has #{sheet.sections.map(&:name).join(", ")}" unless sheet.section(name)

      sections[name] = sections[name].to_h.merge(section.except("name"))
    end
    arrangement = Arrangement.from_h(data.merge("sounds" => sounds, "sections" => sections), sheet)

    change = SongChange.record(song, args["summary"].presence || "Band geändert") do
      song.update!(arrangement: arrangement.to_h, arrangement_status: "ready")
    end
    changed(change)
  rescue Arrangement::Invalid => e
    raise SongTools::Error, e.message
  end

  private

  def checked_sounds(given)
    given.each do |voice, sound|
      next if voice == "distorted"

      allowed = Arrangement::SOUNDS.fetch(voice.to_sym) { raise SongTools::Error, "no voice #{voice.inspect}" }
      raise SongTools::Error, "#{voice} cannot be #{sound.inspect}, only #{allowed.join(", ")}" unless allowed.include?(sound.to_s.to_sym)
    end
  end
end
