require "rails_helper"
require "open3"

# Only what works without a running Sonic Pi; the sending itself is covered
# by spec/lib/sonic_pi_spec.rb.
RSpec.describe "bin/play" do
  def play(*args)
    Open3.capture3(Rails.root.join("bin/play").to_s, *args)
  end

  it "explains itself" do
    out, _, status = play("--help")
    expect(status).to be_success
    expect(out).to include("bin/play <datei>", "--record")
  end

  it "loads the client without Rails" do
    _, err, _ = play("--status")
    expect(err).not_to include("Error")
  end

  it "says so when the file is missing" do
    _, err, status = play("examples/nope/live.rb")
    expect(status).not_to be_success
    expect(err).to include("nicht gefunden")
  end
end
