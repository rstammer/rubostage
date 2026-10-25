# Today's chat client: `claude -p` with the song tools over MCP, on the
# player's Claude subscription. The place to swap for a RubyLLM client.
class SongTools::ClaudeCliClient
  def initialize(cli: ClaudeCli.new)
    @cli = cli
  end

  def call(prompt, toolbox:)
    @cli.call(prompt, mcp: toolbox.mcp)
  end
end
