require "rails_helper"

RSpec.describe "Playing from the chat" do
  let(:song) { create(:song, :ready) }

  before do
    allow(Player).to receive(:play)
    allow(Player).to receive(:stop)
    NowPlaying.started_song_id = nil
  end

  it "starts the song as the footswitch does" do
    SongTools::Play.new.call(song, {})
    expect(Player).to have_received(:play).with(song.playable_code)
    expect(NowPlaying.started_song_id).to eq(song.id)
  end

  it "stops it" do
    NowPlaying.current_song_id = song.id
    SongTools::Stop.new.call(song, {})
    expect(Player).to have_received(:stop)
    expect(NowPlaying.current_song_id).to be_nil
  end

  it "says so when Sonic Pi is not running" do
    allow(Player).to receive(:play).and_raise(Player::NotRunning)
    expect { SongTools::Play.new.call(song, {}) }.to raise_error(SongTools::Error, /Sonic Pi/)
  end
end
