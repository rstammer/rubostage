class Song < ApplicationRecord
  STATUSES = %w[pending ready failed].freeze

  validates :request, presence: true
  validates :status, inclusion: {in: STATUSES}

  broadcasts_refreshes

  scope :newest_first, -> { order(created_at: :desc) }

  STATUSES.each do |name|
    define_method(:"#{name}?") { status == name }
  end

  def lead_sheet
    SongSheet.from_h(sheet) if ready? && sheet.present?
  end

  # Built fresh from the sheet on every play, so songs made before a change to
  # the groove pick it up too.
  def playable_code
    Groove.new(lead_sheet, song_id: id, osc_port: Rails.application.config.x.osc_port).code
  end

  def display_title
    title.presence || request
  end
end
