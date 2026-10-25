# For tools that change what the editor shows: they start from the song as
# the editor has it, change the fields and the section rows, and save it
# through SongEditor, so the editor's checks apply, as one undoable change.
module SongTools::ThroughEditor
  FIELDS = %w[title artist key bpm beats form tuning tone lyrics].freeze

  private

  def save_through_editor(song, summary)
    current = SongEditor.for(song)
    params = FIELDS.to_h { |field| [field, current.public_send(field)] }
    rows = current.rows.reject(&:blank?).map { |row| row_params(row) }
    yield params, rows
    params["sections"] = rows.each_with_index.to_h { |row, i| [i.to_s, row] }

    SongChange.record(song, summary) do
      editor = SongEditor.new(song, params)
      raise SongTools::Error, editor.error unless editor.save
    end
  end

  def row_params(row)
    {"original" => row.original, "name" => row.name, "chords" => row.chords, "tab" => row.tab, "bass_tab" => row.bass_tab,
     "energy" => row.energy, "groove" => row.groove, "guitar" => row.guitar, "swing" => row.swing, "fill" => row.fill ? "1" : "0"}
  end

  def row_named(rows, name)
    rows.find { |row| row["name"] == name } or
      raise SongTools::Error, "no section #{name.inspect}, the song has #{rows.map { |row| row["name"] }.join(", ")}"
  end
end
