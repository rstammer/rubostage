# Changes the sheet the way the editor does, so the same checks apply:
# title, key, tempo, bar, form, and per section its chords and tabs. Only
# what is given changes; a section's band part stays with it.
class SongTools::EditSheet < SongTools::Tool
  define(
    name: "edit_sheet",
    description: "Change the song's sheet. Give only what changes. Chords are written like the " \
      "chart: bars split by \"|\", chords within a bar by spaces, \"%\" holds the chord before. " \
      "A section given by a name that does not exist yet is added; add it to the form too. " \
      "The busker can undo every change.",
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
            properties: {
              name: {type: "string"}, rename_to: {type: "string"}, chords: {type: "string"},
              tab: {type: "string", description: "Guitar tab, six lines, sixteen characters per bar; empty removes it."},
              bass_tab: {type: "string", description: "Bass tab, four lines; empty removes it. Silences the bass line in its section."}
            },
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
    current = SongEditor.for(song)
    params = SHEET_FIELDS.to_h { |field| [field, args.fetch(field, current.public_send(field))] }
    params["form"] = args["form"] ? Array(args["form"]).join(", ") : current.form
    params.merge!("tuning" => current.tuning, "tone" => current.tone, "lyrics" => current.lyrics)
    params["sections"] = sections(current.rows.reject(&:blank?), args).each_with_index.to_h { |row, i| [i.to_s, row] }

    change = SongChange.record(song, args["summary"].presence || "Gerüst geändert") do
      editor = SongEditor.new(song, params)
      raise SongTools::Error, editor.error unless editor.save
    end
    changed(change)
  end

  private

  def sections(rows, args)
    removed = Array(args["remove_sections"])
    given = Array(args["sections"]).index_by { |section| section["name"] }
    kept = rows.reject { |row| removed.include?(row.name) }.map do |row|
      change = given.delete(row.name) || {}
      row_params(row).merge(
        "name" => change["rename_to"].presence || row.name,
        "chords" => change.fetch("chords", row.chords),
        "tab" => change.fetch("tab", row.tab), "bass_tab" => change.fetch("bass_tab", row.bass_tab)
      )
    end
    kept + given.values.map do |section|
      {"original" => "", "name" => section["name"], "chords" => section["chords"].to_s,
       "tab" => section["tab"].to_s, "bass_tab" => section["bass_tab"].to_s}
    end
  end

  def row_params(row)
    {"original" => row.original, "energy" => row.energy, "groove" => row.groove, "guitar" => row.guitar,
     "swing" => row.swing, "fill" => row.fill ? "1" : "0"}
  end
end
