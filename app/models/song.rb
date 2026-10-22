class Song < ApplicationRecord
  STATUSES = %w[pending ready failed].freeze
  # A wish is written by Claude; a manual song is Robin's own sheet.
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

  # Built fresh from the sheet on every play, so songs made before a change to
  # the groove pick it up too.
  def playable_code
    groove.code
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

  def display_title
    title.presence || request.presence || "Neuer Song"
  end
end
