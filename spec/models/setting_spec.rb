require "rails_helper"

RSpec.describe Setting do
  around do |example|
    Dir.mktmpdir { |dir| @dir = Pathname(dir) and example.run }
  end

  it "falls back to SONGS_ROOT or the app's exports folder for the songs" do
    expect(described_class.songs_root).to eq(Rails.application.config.x.songs_root)
  end

  it "keeps the songs folder once one is chosen" do
    described_class.songs_root = @dir.to_s
    expect(described_class.songs_root).to eq(@dir)
  end

  it "reads a leading tilde as the home folder" do
    expect(described_class.expand("~/songs")).to eq(Pathname(Dir.home).join("songs"))
  end

  it "takes no folder that is not there" do
    expect { described_class.songs_root = @dir.join("missing").to_s }.to raise_error(Setting::Invalid, /gibt es nicht/)
  end

  it "takes no folder it cannot write to" do
    @dir.chmod(0o500)
    expect { described_class.songs_root = @dir.to_s }.to raise_error(Setting::Invalid, /nicht schreiben/)
  ensure
    @dir.chmod(0o700)
  end
end
