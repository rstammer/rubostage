# Claude's answer to the last question in a song's conversation. It takes as
# long as `claude -p` does, so it runs in the background; the answer shows up
# in the open chat as it is written and stays there when it is done.
class SongChatJob < ApplicationJob
  def perform(song)
    draft = ChatDraft.new(song, key: job_id)
    answer = SongChat.new(song).call(on_tool: ->(name) { draft.working(name) }) { |piece| draft.write(piece) }
    draft.remove
    song.messages.create!(role: "assistant", body: answer)
  rescue ClaudeCli::Failed => e
    Rails.logger.warn("Chat about song #{song.id} failed: #{e.message}")
    draft&.remove
    song.messages.create!(role: "assistant", body: "Gerade keine Antwort von Claude. Noch mal fragen?")
  end
end
