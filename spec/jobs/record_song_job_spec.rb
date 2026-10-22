require "rails_helper"

RSpec.describe RecordSongJob do
  let(:song) { create(:song, :ready) }

  after { FileUtils.rm_f(song.recording_path) }

  it "records the song and marks the take as ready" do
    allow(Player).to receive(:record) { |_code, path, _seconds| File.write(path, "RIFF") }
    described_class.perform_now(song)
    expect(Player).to have_received(:record).with(song.playable_code, song.recording_path.to_s, song.recording_seconds)
    expect(song.reload.recording_status).to eq("ready")
  end

  it "says so when Sonic Pi is not running" do
    allow(Player).to receive(:record).and_raise(Player::NotRunning)
    described_class.perform_now(song)
    expect(song.reload.recording_status).to eq("failed")
  end
end
