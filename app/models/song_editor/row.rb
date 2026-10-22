# One section as the editor shows it: its name (and the name it had, so a
# renamed section keeps its arrangement and tab), the chords as text, how the
# band plays it, and its guitar and bass tabs.
class SongEditor::Row
  FIELDS = %i[original name chords energy groove guitar swing fill tab bass_tab].freeze

  attr_reader(*FIELDS)

  def self.from_params(data)
    data = data.to_h.stringify_keys
    new(
      original: data["original"].to_s, name: data["name"].to_s.strip, chords: data["chords"].to_s,
      energy: data["energy"].presence&.to_i, groove: data["groove"].presence, guitar: data["guitar"].presence,
      swing: data["swing"].presence&.to_f, fill: data["fill"].to_s == "1",
      tab: ticked(data, "riff_guitar", "tab"), bass_tab: ticked(data, "riff_bass", "bass_tab")
    )
  end

  # A tab whose box is unticked is dropped; without a box, it is kept.
  def self.ticked(data, box, field)
    (data[box].to_s == "0") ? "" : data[field].to_s
  end

  def self.blank
    new(original: "", name: "", chords: "", energy: nil, groove: nil, guitar: nil, swing: nil, fill: false, tab: "", bass_tab: "")
  end

  def initialize(original:, name:, chords:, energy:, groove:, guitar:, swing:, fill:, tab:, bass_tab: "")
    @original = original
    @name = name
    @chords = chords
    @energy = energy
    @groove = groove
    @guitar = guitar
    @swing = swing
    @fill = fill
    @tab = tab
    @bass_tab = bass_tab
  end

  def blank? = name.empty? && chords.strip.empty?

  # "B | C#m\nG#m E" as bars: bar lines and line breaks split bars, spaces
  # split the chords within one. An empty bar between two bar lines, or a %,
  # holds the chord before it; bar lines at the ends of a line are only
  # frames.
  def bars
    chords.lines.map(&:strip).reject(&:empty?).flat_map do |line|
      line.delete_prefix("|").delete_suffix("|").split("|", -1).map { |bar| bar.split - [SongSheet::Section::HOLD] }
    end
  end

  # What the editor changes in this section's part of the arrangement.
  def arrangement_fields
    {"energy" => energy, "groove" => groove, "guitar" => guitar, "swing" => swing, "fill" => fill}.compact
  end
end
