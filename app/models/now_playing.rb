# Where a song is right now, from the step index Sonic Pi reports: the chord,
# the one after it, the section, and which chord on the sheet to mark. An
# index of -1 means the song has played its closing chord.
class NowPlaying
  Step = Struct.new(:section, :section_index, :form_position, :position, :chord)

  attr_reader :song, :index

  # The song Sonic Pi last reported a step for. Lives in the server process,
  # where the listener runs and jobs run inline.
  class << self
    attr_accessor :current_song_id
  end

  def self.broadcast(song, index)
    now = new(song, index)
    Turbo::StreamsChannel.broadcast_replace_to(
      song, :now, target: "now_playing", partial: "songs/now", locals: {now: now}
    )
    # A queued command takes effect at a section boundary, so that is where
    # the note about it goes away.
    Turbo::StreamsChannel.broadcast_update_to(song, :now, target: "queued", html: "") if now.section_start?
  end

  # index nil means nothing is playing yet.
  def initialize(song, index)
    @song = song
    @index = index
  end

  def playing? = !index.nil?

  def finished? = playing? && index.negative?

  def chord = current&.chord

  def section = current&.section

  def form_position = current&.form_position

  def next_chord
    return unless current

    following = steps[index + 1]
    following ? following.chord : "Schluss"
  end

  def section_start?
    finished? || current&.position&.zero?
  end

  # DOM id of the current chord on the sheet, which shows each section once.
  def sheet_id
    "chord-#{current.section_index}-#{current.position}" if current
  end

  private

  def current
    steps[index] if playing? && !finished?
  end

  def steps
    @steps ||= begin
      sheet = song.lead_sheet
      sheet.played_sections.each_with_index.flat_map do |section, form_position|
        section_index = sheet.sections.index(section)
        section.bars.flatten.each_with_index.map do |chord, i|
          Step.new(section.name, section_index, form_position, i, chord.to_s)
        end
      end
    end
  end
end
