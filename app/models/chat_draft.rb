# Claude's answer while it is being written, shown in the chat as it grows.
# Each answer has its own draft, so two questions at once do not mix. The
# page is updated at most every so often; the finished message replaces it.
class ChatDraft
  def initialize(song, key:, every: 0.25, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
    @song = song
    @id = "draft_#{key}"
    @every = every
    @clock = clock
    @text = +""
    @doing = nil
    @shown_at = nil
  end

  def write(piece)
    @text << piece
    @doing = nil
    show
  end

  # While Claude uses a tool, the draft says what it is doing.
  def working(tool_name)
    @doing = SongTools.activity(tool_name)
    show(now: true)
  end

  def remove
    Turbo::StreamsChannel.broadcast_remove_to(@song, :chat, target: @id) if @shown_at
  end

  private

  def show(now: false)
    time = @clock.call
    return if !now && @shown_at && time - @shown_at < @every

    action = @shown_at ? :broadcast_replace_to : :broadcast_append_to
    options = @shown_at ? {target: @id} : {target: "chat_messages"}
    Turbo::StreamsChannel.public_send(action, @song, :chat, **options,
      partial: "song_messages/draft", locals: {id: @id, text: @text.dup, doing: @doing})
    @shown_at = time
  end
end
