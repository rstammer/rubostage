require "rails_helper"

RSpec.describe SonicPiApp do
  let(:app_line) { "/Applications/Sonic Pi.app/Contents/MacOS/Sonic Pi\n" }

  before { allow(SonicPi).to receive(:running).and_return(nil) }

  it "is ready once the server answers" do
    allow(SonicPi).to receive(:running).and_return(SonicPi.new(1, 2))
    expect(described_class.state).to eq(:ready)
  end

  it "is starting while the app is open but the server not yet up" do
    allow(described_class).to receive(:processes).and_return("/usr/bin/zsh\n#{app_line}")
    expect(described_class.state).to eq(:starting)
  end

  it "is off when neither is there" do
    allow(described_class).to receive(:processes).and_return("/usr/bin/zsh\n")
    expect(described_class.state).to eq(:off)
  end

  # open passes the environment on, and Sonic Pi's own Ruby dies at boot on
  # the app's RUBYOPT=-rbundler/setup, GEM_HOME and BUNDLE_GEMFILE.
  it "launches the app without the app's Ruby and Bundler environment" do
    allow(described_class).to receive(:system).and_return(true)
    described_class.launch
    expect(described_class).to have_received(:system) do |env, *command|
      expect(command).to eq(["open", "-a", "Sonic Pi"])
      expect(env).to include("RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil, "GEM_HOME" => nil)
      expect(env.values.compact).to be_empty
    end
  end
end
