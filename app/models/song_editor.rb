# Edits a song after the fact: title, key, tempo, form, the chords of each
# section, how the band plays it, and the riffs tabbed in. Everything is
# checked the way a fresh song is, and nothing is stored unless all of it
# reads.
class SongEditor
  attr_reader :song, :title, :artist, :key, :bpm, :form, :tuning, :tone, :rows, :error

  def self.for(song)
    sheet = song.lead_sheet
    arrangement = song.full_arrangement
    riffs = song.riffs || RiffTrack.from_h({})
    rows = sheet.sections.map do |section|
      part = arrangement&.section(section.name)
      SongEditor::Row.new(
        original: section.name, name: section.name,
        chords: section.chart,
        energy: part&.energy, groove: part&.groove&.to_s, guitar: part&.guitar&.to_s,
        swing: part&.swing, fill: part&.fill || false, tab: riffs.tabs[section.name].to_s
      )
    end
    new(song, {
      "title" => sheet.title, "artist" => sheet.artist, "key" => sheet.key, "bpm" => sheet.bpm,
      "form" => sheet.form.join(", "), "tuning" => riffs.tuning, "tone" => riffs.tone
    }, rows: rows + [SongEditor::Row.blank])
  end

  # A song written from scratch: nothing filled in but the tab settings,
  # and a few rows to start the first sections in.
  def self.blank(song)
    new(song, {"tuning" => "standard", "tone" => "crunch"}, rows: Array.new(3) { SongEditor::Row.blank })
  end

  def initialize(song, params, rows: nil)
    params = params.to_h.stringify_keys
    @song = song
    @title = params["title"].to_s.strip
    @artist = params["artist"].to_s.strip
    @key = params["key"].to_s.strip
    @bpm = params["bpm"]
    @form = params["form"].to_s
    @tuning = params["tuning"].to_s
    @tone = params["tone"].to_s
    @rows = rows || params["sections"].to_h.sort_by { |index, _| index.to_i }.map { |_, row| SongEditor::Row.from_params(row) }
  end

  def arranged? = song.arrangement.present?

  def save
    before = song.lead_sheet&.then { |sheet| structure(sheet) }
    sheet = build_sheet
    riffs = RiffTrack.from_h({"tuning" => tuning, "tone" => tone, "tabs" => kept_rows.to_h { |row| [row.name, row.tab] }}).validate!
    song.update!(
      title: sheet.title, artist: sheet.artist, key: sheet.key, bpm: sheet.bpm, sheet: sheet.to_h,
      arrangement: (build_arrangement(sheet).to_h if arranged?), riff_track: riffs.to_h, status: "ready"
    )
    song.rebuild_code!
    @swappable = structure(sheet) == before
    true
  rescue SongSheet::Invalid, Arrangement::Invalid, Tab::Invalid => e
    @error = e.message
    false
  end

  # Whether the change can go into a song that is playing: the conductor
  # keeps its tempo and the length of every part, so only those may stay.
  def swappable? = @swappable == true

  private

  def kept_rows = rows.reject(&:blank?)

  def build_sheet
    SongSheet.from_h(
      "title" => title, "artist" => artist, "key" => key, "bpm" => Integer(bpm.to_s, exception: false),
      "sections" => kept_rows.map { |row| {"name" => row.name, "bars" => row.bars} },
      "form" => form.split(",").map(&:strip).reject(&:empty?)
    )
  end

  def build_arrangement(sheet)
    old_parts = song.arrangement["sections"].to_h
    parts = kept_rows.to_h { |row| [row.name, old_parts.fetch(row.original, {}).merge(row.arrangement_fields)] }
    Arrangement.from_h(song.arrangement.merge("sections" => parts), sheet)
  end

  def structure(sheet)
    [sheet.bpm, sheet.played_sections.map { |section| section.bars.size }]
  end
end
