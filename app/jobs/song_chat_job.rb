# Claude's answer to the last question in a song's conversation. It takes as
# long as `claude -p` does, so it runs in the background and lands in the
# editor when it is there.
class SongChatJob < ApplicationJob
  def perform(song)
    song.messages.create!(role: "assistant", body: SongChat.new(song).call)
  rescue ClaudeCli::Failed => e
    Rails.logger.warn("Chat about song #{song.id} failed: #{e.message}")
    song.messages.create!(role: "assistant", body: "Gerade keine Antwort von Claude. Noch mal fragen?")
  end
end
