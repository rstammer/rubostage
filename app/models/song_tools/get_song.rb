# The song as it stands: sheet, band and riffs, never the lyrics.
class SongTools::GetSong < SongTools::Tool
  define(
    name: "get_song",
    description: "Read the song as it is right now: key, tempo, bar, form, chords per section, " \
      "the band's sounds and parts per section, and the riffs as tabs.",
    input_schema: {type: "object", properties: {}}
  )

  def call(song, _args)
    sheet = song.lead_sheet
    riffs = song.riffs || RiffTrack.from_h({})
    {
      "title" => sheet.title, "artist" => sheet.artist, "key" => sheet.key, "bpm" => sheet.bpm,
      "beats" => sheet.beats, "form" => sheet.form,
      "sections" => sheet.sections.map do |section|
        {"name" => section.name, "chords" => section.chart,
         "tab" => riffs.tabs[section.name], "bass_tab" => riffs.bass_tabs[section.name]}.compact
      end,
      "band" => song.full_arrangement&.to_h,
      "riffs" => {"tuning" => riffs.tuning, "tone" => riffs.tone}
    }.to_json
  end
end
