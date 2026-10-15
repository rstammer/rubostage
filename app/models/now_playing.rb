# Where a song is right now, from the step index Sonic Pi reports: the chord,
# the one after it, the section, and which chord on the sheet to mark.
class NowPlaying
  Step = Struct.new(:section, :section_index, :position, :chord)

  attr_reader :song, :index

  def self.broadcast(song, index)
    Turbo::StreamsChannel.broadcast_replace_to(
      song, :now, target: "now_playing", partial: "songs/now", locals: {now: new(song, index)}
    )
  end

  # index nil means nothing is playing yet.
  def initialize(song, index)
    @song = song
    @index = index
  end

  def playing? = !index.nil?

  def chord = current&.chord

  def section = current&.section

  def next_chord
    steps[(index + 1) % steps.size].chord if playing?
  end

  # DOM id of the current chord on the sheet, which shows each section once.
  def sheet_id
    "chord-#{current.section_index}-#{current.position}" if playing?
  end

  private

  def current
    steps[index % steps.size] if playing?
  end

  def steps
    @steps ||= begin
      sheet = song.lead_sheet
      sheet.played_sections.flat_map do |section|
        section_index = sheet.sections.index(section)
        chords = section.bars.flatten
        chords.each_with_index.map { |chord, i| Step.new(section.name, section_index, i, chord.to_s) }
      end
    end
  end
end
