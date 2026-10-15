require "rails_helper"

RSpec.describe "Songs", type: :request do
  include ActiveJob::TestHelper

  describe "GET /" do
    it "shows the wish field and the songs made so far" do
      create(:song, :ready)
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Starlight", 'name="song[request]"')
    end
  end

  describe "POST /songs" do
    it "takes the wish and starts generating" do
      expect {
        post songs_path, params: {song: {request: "Starlight von Muse"}}
      }.to change(Song, :count).by(1).and have_enqueued_job(GenerateSongJob)
      expect(response).to redirect_to(song_path(Song.last))
    end

    it "sends an empty wish back" do
      post songs_path, params: {song: {request: " "}}
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /songs/:id" do
    it "shows the chords of a ready song" do
      song = create(:song, :ready)
      get song_path(song)
      expect(response.body).to include("C#m", "122", 'id="chord-0-1"', 'id="now_playing"')
    end

    it "says it is still working on a pending song" do
      song = create(:song)
      get song_path(song)
      expect(response.body).to include("Starlight von Muse")
    end
  end

  describe "playing" do
    let(:song) { create(:song, :ready) }

    it "plays a song" do
      allow(Player).to receive(:play)
      post song_playback_path(song)
      expect(Player).to have_received(:play).with(song.playable_code)
      expect(response).to redirect_to(song_path(song))
    end

    it "says so when Sonic Pi is not running" do
      allow(Player).to receive(:play).and_raise(Player::NotRunning)
      post song_playback_path(song)
      follow_redirect!
      expect(response.body).to include("Sonic Pi läuft nicht")
    end

    it "stops" do
      allow(Player).to receive(:stop)
      delete playback_path, headers: {"HTTP_REFERER" => song_path(song)}
      expect(Player).to have_received(:stop)
    end
  end
end
