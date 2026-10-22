require "rails_helper"

RSpec.describe ControlPanel do
  let(:panel) { described_class.new }

  before { allow(SonicPiApp).to receive(:state).and_return(:ready) }
  after { NowPlaying.current_song_id = NowPlaying.last_step_at = NowPlaying.started_song_id = nil }

  it "passes on the state of Sonic Pi" do
    expect(panel.sonic_pi).to eq(:ready)
  end

  describe "#song" do
    let(:song) { create(:song, :ready) }

    it "is the song Sonic Pi reported a step for just now" do
      NowPlaying.current_song_id = song.id
      NowPlaying.last_step_at = 1.second.ago
      expect(panel.song).to eq(song)
    end

    it "is nothing once the steps have stopped coming" do
      NowPlaying.current_song_id = song.id
      NowPlaying.last_step_at = 5.seconds.ago
      expect(panel.song).to be_nil
    end

    it "is nothing before anything played" do
      expect(panel.song).to be_nil
    end
  end

  describe "#thinking?" do
    it "is on while a lead sheet is being written" do
      create(:song)
      expect(panel).to be_thinking
    end

    it "is on while an arrangement is being written" do
      create(:song, :ready, arrangement_status: "pending")
      expect(panel).to be_thinking
    end

    it "ignores a job that died long ago" do
      create(:song, updated_at: 1.hour.ago)
      expect(panel).not_to be_thinking
    end

    it "is off when nothing is being written" do
      create(:song, :ready)
      expect(panel).not_to be_thinking
    end
  end

  describe "#started" do
    let(:song) { create(:song, :ready) }

    it "is the song last started, also after it stopped, so it can start again" do
      NowPlaying.started_song_id = song.id
      expect(panel.started).to eq(song)
    end

    it "is nothing while Sonic Pi is not there to play it" do
      NowPlaying.started_song_id = song.id
      allow(SonicPiApp).to receive(:state).and_return(:off)
      expect(panel.started).to be_nil
    end

    it "is nothing before a song was started" do
      expect(panel.started).to be_nil
    end
  end
end
