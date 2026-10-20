require "rails_helper"

RSpec.describe StepListener do
  let(:song) { create(:song, :ready) }

  it "passes a step on to the song's page" do
    allow(NowPlaying).to receive(:broadcast)
    described_class.handle(OSC.message("/stage/step", song.id, 2))
    expect(NowPlaying).to have_received(:broadcast).with(song, 2)
  end

  it "remembers which song is playing" do
    allow(NowPlaying).to receive(:broadcast)
    described_class.handle(OSC.message("/stage/step", song.id, 0))
    expect(NowPlaying.current_song_id).to eq(song.id)
  end

  it "ignores other addresses" do
    allow(NowPlaying).to receive(:broadcast)
    described_class.handle(OSC.message("/something/else", song.id, 2))
    expect(NowPlaying).not_to have_received(:broadcast)
  end

  it "ignores songs that are gone and packets that are garbage" do
    allow(NowPlaying).to receive(:broadcast)
    described_class.handle(OSC.message("/stage/step", 0, 2))
    described_class.handle("garbage")
    expect(NowPlaying).not_to have_received(:broadcast)
  end
end
