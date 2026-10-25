require "rails_helper"

RSpec.describe ClaudeCli do
  def runner_returning(stdout, success: true, stderr: "")
    lambda do |*command|
      @command = command
      [stdout, stderr, success]
    end
  end

  it "asks claude -p and returns the answer text" do
    cli = described_class.new(runner: runner_returning({result: "hello", is_error: false}.to_json))
    expect(cli.call("Hi")).to eq("hello")
    expect(@command).to include("claude", "-p", "Hi", "--output-format", "json")
  end

  it "raises when claude reports an error" do
    cli = described_class.new(runner: runner_returning({result: "Rate limited", is_error: true}.to_json))
    expect { cli.call("Hi") }.to raise_error(ClaudeCli::Failed, /Rate limited/)
  end

  it "raises when the command fails" do
    cli = described_class.new(runner: runner_returning("", success: false, stderr: "not logged in"))
    expect { cli.call("Hi") }.to raise_error(ClaudeCli::Failed, /not logged in/)
  end

  it "offers the tools of an MCP server, and only those" do
    cli = described_class.new(runner: runner_returning({result: "ok", is_error: false}.to_json))
    cli.call("Hi", mcp: {name: "rubostage", url: "http://127.0.0.1:3000/songs/1/mcp", token: "secret", tools: %w[get_song edit_band]})
    config = JSON.parse(@command[@command.index("--mcp-config") + 1])
    expect(config.dig("mcpServers", "rubostage")).to include("type" => "http", "url" => "http://127.0.0.1:3000/songs/1/mcp")
    expect(config.dig("mcpServers", "rubostage", "headers", "Authorization")).to eq("Bearer secret")
    expect(@command).to include("--strict-mcp-config", "--allowedTools", "mcp__rubostage__get_song,mcp__rubostage__edit_band")
  end

  describe "streaming" do
    def event(type, **data) = data.merge(type: type).to_json
    def delta(text) = event("stream_event", event: {type: "content_block_delta", delta: {type: "text_delta", text: text}})

    def streamer(*lines, success: true, stderr: "")
      lambda do |*command, &each_line|
        @command = command
        lines.each(&each_line)
        [stderr, success]
      end
    end

    it "hands over the answer piece by piece and returns it whole" do
      cli = described_class.new(streamer: streamer(
        event("system", subtype: "init"), event("stream_event", event: {type: "message_start"}),
        delta("Hal"), delta("lo!"), event("result", subtype: "success", is_error: false, result: "Hallo!")
      ))
      pieces = []
      expect(cli.call("Hi") { |text| pieces << text }).to eq("Hallo!")
      expect(pieces).to eq(["Hal", "lo!"])
      expect(@command).to include("--output-format", "stream-json", "--verbose", "--include-partial-messages")
    end

    it "keeps what Claude said before and after using a tool, a paragraph apart" do
      cli = described_class.new(streamer: streamer(
        event("stream_event", event: {type: "message_start"}), delta("Mache ich."),
        event("stream_event", event: {type: "message_start"}), delta("Erledigt."),
        event("result", subtype: "success", is_error: false, result: "Erledigt.")
      ))
      pieces = []
      expect(cli.call("Hi") { |text| pieces << text }).to eq("Mache ich.\n\nErledigt.")
      expect(pieces.join).to eq("Mache ich.\n\nErledigt.")
    end

    it "tells which tool Claude reaches for, by the tool's own name" do
      cli = described_class.new(streamer: streamer(
        event("stream_event", event: {type: "content_block_start", content_block: {type: "tool_use", name: "mcp__rubostage__edit_band"}}),
        event("result", subtype: "success", is_error: false, result: "ok")
      ))
      tools = []
      cli.call("Hi", mcp: {name: "rubostage", url: "u", token: "t", tools: ["edit_band"]}, on_tool: ->(name) { tools << name }) { nil }
      expect(tools).to eq(["edit_band"])
    end

    it "raises when claude reports an error or fails" do
      erring = described_class.new(streamer: streamer(event("result", subtype: "error", is_error: true, result: "Rate limited")))
      expect { erring.call("Hi") { nil } }.to raise_error(ClaudeCli::Failed, /Rate limited/)
      failing = described_class.new(streamer: streamer(success: false, stderr: "not logged in"))
      expect { failing.call("Hi") { nil } }.to raise_error(ClaudeCli::Failed, /not logged in/)
    end
  end
end
