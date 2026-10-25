# Today's chat client: `claude -p` with the song tools over MCP, on the
# player's Claude subscription. The place to swap for a RubyLLM client.
class SongTools::ClaudeCliClient
  def initialize(cli: ClaudeCli.new)
    @cli = cli
  end

  def call(prompt, toolbox:, on_tool: nil, &on_text)
    @cli.call(prompt, mcp: toolbox.mcp, on_tool: on_tool, &on_text)
  end
end
