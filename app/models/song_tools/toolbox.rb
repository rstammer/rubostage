# The tools for one song, as a chat client gets them. Today's client offers
# them to `claude -p` over the app's MCP endpoint; a RubyLLM client would
# wrap each in a RubyLLM::Tool and call #run.
class SongTools::Toolbox
  attr_reader :song, :tools

  def initialize(song, tools: SongTools.all)
    @song = song
    @tools = tools
  end

  def run(name, args)
    tool = tools.find { |candidate| candidate.tool_name == name } or raise SongTools::Error, "no tool #{name.inspect}"
    tool.new.call(song, args.to_h.stringify_keys)
  end

  # Where `claude -p` finds the tools: this song's MCP endpoint in the
  # running app, which holds the playing state and the open pages' streams.
  def mcp
    {name: "rubostage", url: "#{Rails.application.config.x.app_url}/songs/#{song.id}/mcp",
     token: Rails.application.config.x.mcp_token, tools: tools.map(&:tool_name)}
  end
end
