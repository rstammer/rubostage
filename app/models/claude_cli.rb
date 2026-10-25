require "open3"

# Asks the local Claude Code with the local user's login: no API key, but slower. A
# stopgap — anything that answers #call(prompt) with text can take its place.
class ClaudeCli
  class Failed < StandardError; end

  DEFAULT_RUNNER = lambda do |*command|
    out, err, status = Open3.capture3(*command)
    [out, err, status.success?]
  end

  # Hands each line of output to the block as it comes; stderr is read on
  # the side, so a chatty one cannot block the process.
  DEFAULT_STREAMER = lambda do |*command, &each_line|
    Open3.popen3(*command) do |stdin, stdout, stderr, wait|
      stdin.close
      err = Thread.new { stderr.read }
      stdout.each_line(&each_line)
      [err.value, wait.value.success?]
    end
  end

  def initialize(runner: DEFAULT_RUNNER, streamer: DEFAULT_STREAMER)
    @runner = runner
    @streamer = streamer
  end

  # No built-in tools and no saved session. With an MCP server, Claude gets
  # its tools and only those: {name:, url:, token:, tools: [names]}. With a
  # block, the answer comes in pieces as Claude writes it, and on_tool hears
  # the name of each tool Claude reaches for.
  def call(prompt, mcp: nil, on_tool: nil, &on_text)
    command = ["claude", "-p", prompt, "--tools", "", "--no-session-persistence"]
    command += mcp_options(mcp) if mcp
    return stream(command, on_tool: on_tool, prefix: ("mcp__#{mcp[:name]}__" if mcp), &on_text) if on_text

    out, err, ok = @runner.call(*command, "--output-format", "json")
    raise Failed, "claude -p failed: #{err.presence || out}" unless ok

    answer = JSON.parse(out)
    raise Failed, "claude -p: #{answer["result"]}" if answer["is_error"]

    answer["result"].to_s
  rescue JSON::ParserError
    raise Failed, "claude -p gave no JSON: #{out.to_s.truncate(200)}"
  end

  private

  # Everything Claude writes, across the turns around its tool calls, a
  # paragraph apart, as the player saw it come in.
  def stream(command, on_tool:, prefix:)
    text = +""
    turn_written = false
    result = nil
    err, ok = @streamer.call(*command, "--output-format", "stream-json", "--verbose", "--include-partial-messages") do |line|
      event = parse(line) or next
      case event["type"]
      when "stream_event"
        inner = event["event"].to_h
        if inner["type"] == "message_start"
          turn_written = false
        elsif inner.dig("content_block", "type") == "tool_use"
          on_tool&.call(inner.dig("content_block", "name").to_s.delete_prefix(prefix.to_s))
        elsif inner.dig("delta", "type") == "text_delta"
          piece = inner.dig("delta", "text").to_s
          piece = "\n\n#{piece}" if !turn_written && !text.empty?
          turn_written = true
          text << piece
          yield piece
        end
      when "result"
        result = event
      end
    end
    raise Failed, "claude -p: #{result["result"]}" if result&.dig("is_error")
    raise Failed, "claude -p failed: #{err.presence || "no result"}" unless ok && result

    text.presence || result["result"].to_s
  end

  # Lines that are not JSON, like a warning, are no events.
  def parse(line)
    JSON.parse(line)
  rescue JSON::ParserError
    nil
  end

  def mcp_options(mcp)
    server = {type: "http", url: mcp[:url], headers: {"Authorization" => "Bearer #{mcp[:token]}"}}
    ["--mcp-config", {mcpServers: {mcp[:name] => server}}.to_json, "--strict-mcp-config",
      "--allowedTools", mcp[:tools].map { |tool| "mcp__#{mcp[:name]}__#{tool}" }.join(",")]
  end
end
