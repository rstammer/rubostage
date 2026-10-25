# A change Claude made to a song, with the song as it was before, so the
# player can take it back with one button. Taking one back also takes back
# every change after it, since those were made on top of it.
class SongChange < ApplicationRecord
  # What a change may touch. The lyrics are never Claude's to change.
  FIELDS = %w[title artist key bpm sheet arrangement arrangement_status riff_track].freeze

  belongs_to :song

  # How the change reached Sonic Pi, from LiveSwap; set by .record.
  attr_accessor :live

  validates :summary, presence: true

  after_create_commit -> { broadcast_append_to song, :chat, target: "chat_messages", partial: "song_changes/change", locals: {change: self} }
  after_update_commit -> { broadcast_replace_to song, :chat, partial: "song_changes/change", locals: {change: self} }

  # Runs the change and keeps the song as it was before it. Nothing is
  # recorded when the change raises.
  def self.record(song, summary)
    before = song.attributes.slice(*FIELDS)
    structure = song.lead_sheet&.structure
    change = transaction do
      yield
      song.rebuild_code!
      create!(song: song, summary: summary, before: before)
    end
    change.live = LiveSwap.call(song, swappable: song.lead_sheet.structure == structure).first
    change
  end

  def undone? = undone_at.present?

  def undo!
    structure = song.lead_sheet.structure
    transaction do
      song.update!(before)
      song.rebuild_code!
      song.changes_made.where(id: id..).where(undone_at: nil).find_each { |change| change.update!(undone_at: Time.current) }
    end
    LiveSwap.call(song, swappable: song.lead_sheet.structure == structure)
  end
end
