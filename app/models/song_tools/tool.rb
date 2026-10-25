# The shape every tool shares. A tool answers in text for the model; when it
# cannot do what it was asked, it raises SongTools::Error with the reason,
# which goes back to the model so it can try again.
class SongTools::Tool
  class << self
    attr_reader :tool_name, :description, :input_schema

    def define(name:, description:, input_schema:)
      @tool_name = name
      @description = description
      @input_schema = input_schema
    end
  end

  def call(song, args)
    raise NotImplementedError
  end

  LIVE = {
    idle: "The song is not playing; it sounds like this from its next start.",
    restart: "The song is playing, but tempo, bar or a part's length changed: it must be started again (Spielen) to be heard.",
    broken: "The song is playing, but the new code has errors and was not swapped in.",
    swapped: "The song is playing and sounds like this from its next part on."
  }.freeze

  private

  # What the model hears back after a change: done, how it reaches the
  # music, and that it can be taken back.
  def changed(change)
    "Geändert: #{change.summary}. #{LIVE.fetch(change.live)} The busker can undo it with a button."
  end
end
