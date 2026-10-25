require "open3"

# Asks the local Claude Code with the local user's login: no API key, but slower. A
# stopgap — anything that answers #call(prompt) with text can take its place.
class ClaudeCli
  class Failed < StandardError; end

  DEFAULT_RUNNER = lambda do |*command|
    out, err, status = Open3.capture3(*command)
    [out, err, status.success?]
  end

  def initialize(runner: DEFAULT_RUNNER)
    @runner = runner
  end

  # No built-in tools and no saved session. With an MCP server, Claude gets
  # its tools and only those: {name:, url:, token:, tools: [names]}.
  def call(prompt, mcp: nil)
    command = ["claude", "-p", prompt, "--output-format", "json", "--tools", "", "--no-session-persistence"]
    command += mcp_options(mcp) if mcp
    out, err, ok = @runner.call(*command)
    raise Failed, "claude -p failed: #{err.presence || out}" unless ok

    answer = JSON.parse(out)
    raise Failed, "claude -p: #{answer["result"]}" if answer["is_error"]

    answer["result"].to_s
  rescue JSON::ParserError
    raise Failed, "claude -p gave no JSON: #{out.to_s.truncate(200)}"
  end

  private

  def mcp_options(mcp)
    server = {type: "http", url: mcp[:url], headers: {"Authorization" => "Bearer #{mcp[:token]}"}}
    ["--mcp-config", {mcpServers: {mcp[:name] => server}}.to_json, "--strict-mcp-config",
      "--allowedTools", mcp[:tools].map { |tool| "mcp__#{mcp[:name]}__#{tool}" }.join(",")]
  end
end
