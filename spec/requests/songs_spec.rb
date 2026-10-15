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

    it "says when the full arrangement is on its way" do
      song = create(:song, :ready, arrangement_status: "pending")
      get song_path(song)
      expect(response.body).to include("volles Arrangement kommt")
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

  describe "editing" do
    let(:song) { create(:song, :ready) }
    let(:tab) { "e|----------------|\nB|----------------|\nG|----------------|\nD|----------------|\nA|----------------|\nE|0---0---3---5---|\n" }

    def edit_params(chords: "B | C#m | G#m | E", **changes)
      {song: {title: "Starlight", artist: "Muse", key: "B", bpm: "122", form: "Verse", tuning: "standard", tone: "crunch",
              sections: {"0" => {original: "Verse", name: "Verse", chords: chords, tab: tab}}}.merge(changes)}
    end

    it "is reached from the song" do
      get song_path(song)
      expect(response.body).to include(edit_song_path(song))
    end

    it "shows every field, the chords as text and a tab box per section" do
      get edit_song_path(song)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="song[bpm]"', "B | C#m | G#m | E", 'name="song[sections][0][tab]"', 'name="song[sections][1][name]"')
    end

    it "only shows the band's parts once there is an arrangement" do
      get edit_song_path(song)
      expect(response.body).not_to include('name="song[sections][0][groove]"')
      song.update!(arrangement: {"sections" => {}}, arrangement_status: "ready")
      get edit_song_path(song)
      expect(response.body).to include('name="song[sections][0][groove]"', 'name="song[sections][0][guitar]"')
    end

    it "stores the changes and goes back to the song" do
      patch song_path(song), params: edit_params(bpm: "118")
      expect(response).to redirect_to(song_path(song))
      expect(song.reload.bpm).to eq(118)
      expect(song.riffs.tab("Verse")).to be_present
    end

    it "shows what is wrong and keeps the text" do
      patch song_path(song), params: edit_params(chords: "B | Hm")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("B | Hm")
    end

    it "swaps the new voices into the song while it plays" do
      NowPlaying.current_song_id = song.id
      allow(Player).to receive(:upgrade)
      patch song_path(song), params: edit_params
      expect(Player).to have_received(:upgrade).with(song.reload.voices_code)
    ensure
      NowPlaying.current_song_id = nil
    end

    it "leaves a playing song alone when its tempo changed" do
      NowPlaying.current_song_id = song.id
      allow(Player).to receive(:upgrade)
      patch song_path(song), params: edit_params(bpm: "100")
      expect(Player).not_to have_received(:upgrade)
      follow_redirect!
      expect(response.body).to include("neu starten")
    ensure
      NowPlaying.current_song_id = nil
    end
  end
end
