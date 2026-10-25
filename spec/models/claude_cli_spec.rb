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
end
