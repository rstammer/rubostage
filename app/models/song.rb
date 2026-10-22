class Song < ApplicationRecord
  STATUSES = %w[pending ready failed].freeze
  # A wish is written by Claude; a manual song is written by hand.
  ORIGINS = %w[wish manual].freeze

  validates :request, presence: true, if: :wish?
  validates :status, inclusion: {in: STATUSES}
  validates :origin, inclusion: {in: ORIGINS}

  broadcasts_refreshes

  scope :newest_first, -> { order(created_at: :desc) }

  STATUSES.each do |name|
    define_method(:"#{name}?") { status == name }
  end

  ORIGINS.each do |name|
    define_method(:"#{name}?") { origin == name }
  end

  def lead_sheet
    SongSheet.from_h(sheet) if ready? && sheet.present?
  end

  # The code is kept, not built on every play: a song sounds the way it did
  # when it was last saved or arranged, even after the groove has changed.
  # rebuild_code! brings a song up to the current groove.
  def playable_code
    code.presence || rebuild_code!
  end

  # Each build also lands in the songs folder. A song taken over by hand
  # there, or a folder that has gone away, is no reason to lose the build.
  def rebuild_code!
    update!(code: groove.code)
    export
    code
  end

  def export
    SongExport.new(self).call
  rescue SongExport::HandWritten, SystemCallError => e
    Rails.logger.info("Song #{id} not written to the songs folder: #{e.message}")
  end

  # Just the voices, for swapping in the arrangement while the song plays.
  def voices_code
    groove.voices_code
  end

  def full_arrangement
    Arrangement.from_h(arrangement, lead_sheet) if arrangement.present?
  end

  def riffs
    RiffTrack.from_h(riff_track) if riff_track.present?
  end

  def groove
    Groove.new(lead_sheet, song_id: id, osc_port: Rails.application.config.x.osc_port,
      arrangement: full_arrangement, riffs: riffs)
  end

  # One take of the song as a WAV: Sonic Pi cannot render faster than it
  # plays, so the take runs as long as the song, from the count-in to the
  # ring of the closing chord.
  COUNT_IN_BEATS = 4
  RING_OUT_SECONDS = 4

  def recording_seconds
    sheet = lead_sheet
    beats = sheet.played_sections.sum { |section| section.steps(sheet.beats).sum(&:last) }
    (COUNT_IN_BEATS + beats) * 60.0 / sheet.bpm + RING_OUT_SECONDS
  end

  def recording_path
    Rails.root.join("storage/recordings/song-#{id}.wav")
  end

  def recording_filename
    "#{display_title.tr("/\\", "-")}.wav"
  end

  def display_title
    title.presence || request.presence || "Neuer Song"
  end
end
