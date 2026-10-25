# Changes the sheet the way the editor does: title, key, tempo, bar, form,
# and per section its chords. Only what is given changes; a section's band
# part and riffs stay with it.
class SongTools::EditSheet < SongTools::Tool
  include SongTools::ThroughEditor

  define(
    name: "edit_sheet",
    activity: "ändert das Gerüst",
    description: "Change the song's sheet. Give only what changes. Chords are written like the " \
      "chart: bars split by \"|\", chords within a bar by spaces, \"%\" holds the chord before. " \
      "A section given by a name that does not exist yet is added; add it to the form too. " \
      "Riffs are changed with edit_riffs. The busker can undo every change.",
    input_schema: {
      type: "object",
      properties: {
        summary: {type: "string", description: "What the change does, in a few German words, for the undo button."},
        title: {type: "string"}, artist: {type: "string"}, key: {type: "string"},
        bpm: {type: "integer", minimum: SongSheet::BPM_RANGE.min, maximum: SongSheet::BPM_RANGE.max},
        beats: {type: "integer", enum: SongSheet::BEATS},
        form: {type: "array", items: {type: "string"}, description: "Section names in playing order."},
        sections: {
          type: "array",
          items: {
            type: "object",
            properties: {name: {type: "string"}, rename_to: {type: "string"}, chords: {type: "string"}},
            required: ["name"]
          }
        },
        remove_sections: {type: "array", items: {type: "string"}}
      },
      required: ["summary"]
    }
  )

  SHEET_FIELDS = %w[title artist key bpm beats].freeze

  def call(song, args)
    change = save_through_editor(song, args["summary"].presence || "Gerüst geändert") do |params, rows|
      params.merge!(args.slice(*SHEET_FIELDS))
      params["form"] = Array(args["form"]).join(", ") if args["form"]
      rows.reject! { |row| Array(args["remove_sections"]).include?(row["name"]) }
      Array(args["sections"]).each do |section|
        row = rows.find { |candidate| candidate["name"] == section["name"] }
        next rows << {"original" => "", "name" => section["name"], "chords" => section["chords"].to_s} unless row

        row["chords"] = section["chords"] if section.key?("chords")
        row["name"] = section["rename_to"] if section["rename_to"].present?
      end
    end
    changed(change)
  end
end
