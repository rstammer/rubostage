require "open3"

# Asks the local Claude Code with Robin's login: no API key, but slower. A
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

  def call(prompt)
    # No tools and no saved session: one question, one answer from what Claude
    # already knows.
    out, err, ok = @runner.call(
      "claude", "-p", prompt, "--output-format", "json", "--tools", "", "--no-session-persistence"
    )
    raise Failed, "claude -p failed: #{err.presence || out}" unless ok

    answer = JSON.parse(out)
    raise Failed, "claude -p: #{answer["result"]}" if answer["is_error"]

    answer["result"].to_s
  rescue JSON::ParserError
    raise Failed, "claude -p gave no JSON: #{out.to_s.truncate(200)}"
  end
end
