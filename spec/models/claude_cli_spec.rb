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
end
