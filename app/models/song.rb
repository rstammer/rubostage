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

  def display_title
    title.presence || request
  end
end
