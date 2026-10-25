# One turn of the conversation about a song in the editor: the player's
# question or Claude's answer. Each lands in the open editor as it is made.
class SongMessage < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :song

  validates :role, inclusion: {in: ROLES}
  validates :body, presence: true

  after_create_commit -> { broadcast_append_to song, :chat, target: "chat_messages", partial: "song_messages/message", locals: {message: self} }
  # The lamp goes out with the answer to the last question still open.
  after_create_commit -> { broadcast_update_to song, :chat, target: "chat_thinking", html: "" }, unless: -> { user? || song.awaiting_answer? }

  def user? = role == "user"
end
