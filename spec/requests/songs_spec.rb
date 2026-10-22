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

    it "lists the repertoire with a way to write a new song and to edit each one" do
      song = create(:song, :ready)
      get root_path
      expect(response.body).to include("Repertoire", new_song_path, edit_song_path(song))
    end

    it "marks songs written by hand" do
      create(:song, :ready, :manual, artist: "")
      get root_path
      expect(response.body).to include("eigener Song")
    end

    it "keeps the case of a key, so minor stays minor" do
      song = create(:song, :ready)
      song.update!(key: "Gm")
      get root_path
      expect(response.body).to match(%r{<span class="font-display[^"]*">Gm</span>})
      expect(response.body).not_to match(/class="silk[^"]*">[^<]*Gm/)
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

    it "marks a held bar with % and numbers only the chords that sound" do
      song = create(:song, :ready)
      song.update!(sheet: song.sheet.merge("sections" => [{"name" => "Verse", "bars" => [["B"], [], ["E"]]}]))
      get song_path(song)
      expect(response.body).to include("%", 'id="chord-0-1">E<')
      expect(response.body).not_to include('id="chord-0-2"')
    end

    it "says when the full arrangement is on its way" do
      song = create(:song, :ready, arrangement_status: "pending")
      get song_path(song)
      expect(response.body).to include("Arrangement kommt", "lamp-blink")
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

    it "lets the bar be four or two beats" do
      get edit_song_path(song)
      expect(response.body).to include('name="song[beats]"', "2/4")
    end

    it "offers a guitar and a bass riff per section, each behind a tick" do
      get edit_song_path(song)
      expect(response.body).to include('name="song[sections][0][riff_guitar]"', 'name="song[sections][0][riff_bass]"',
        'name="song[sections][0][bass_tab]"')
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

  describe "writing a new song" do
    let(:new_params) do
      {song: {origin: "manual", title: "Rahmersee", artist: "", key: "Am", bpm: "96", form: "", tuning: "standard", tone: "crunch",
              sections: {"0" => {original: "", name: "Verse", chords: "Am | F | C | G"}}}}
    end

    it "starts from an empty editor" do
      get new_song_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Neuer Song", 'name="song[sections][2][name]"', 'action="/songs"')
    end

    it "stores the sheet without asking Claude and goes to the song" do
      expect { post songs_path, params: new_params }.to change(Song, :count).by(1)
      song = Song.last
      expect(song).to be_manual
      expect(song).to be_ready
      expect(response).to redirect_to(song_path(song))
      expect(GenerateSongJob).not_to have_been_enqueued
    end

    it "shows what is wrong and keeps the text" do
      post songs_path, params: new_params.deep_merge(song: {sections: {"0" => {chords: "Am | Hm"}}})
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Am | Hm")
      expect(Song.count).to eq(0)
    end
  end

  describe "arranging" do
    let(:song) { create(:song, :ready) }

    it "offers to arrange a song that has none" do
      get song_path(song)
      expect(response.body).to include("Arrangieren lassen", 'name="wish"')
    end

    it "asks before replacing an arrangement" do
      song.update!(arrangement: {"sections" => {}}, arrangement_status: "ready")
      get song_path(song)
      expect(response.body).to include("Neu arrangieren", "data-turbo-confirm")
    end

    it "offers nothing while an arrangement is on its way" do
      song.update!(arrangement_status: "pending")
      get song_path(song)
      expect(response.body).not_to include("Arrangieren lassen", "Neu arrangieren")
    end

    it "sends the song and the wish to Claude" do
      expect {
        post song_arrangement_path(song), params: {wish: "mehr Funk"}
      }.to have_enqueued_job(ArrangeSongJob).with(song, wish: "mehr Funk")
      expect(song.reload.arrangement_status).to eq("pending")
      expect(response).to redirect_to(song_path(song))
    end
  end

  describe "deleting" do
    let(:song) { create(:song, :ready) }

    before do
      allow(Player).to receive(:stop)
      NowPlaying.current_song_id = nil
    end

    it "is offered on the song, with a question first" do
      get song_path(song)
      expect(response.body).to include("Löschen", "data-turbo-confirm")
    end

    it "removes the song and goes back to the repertoire" do
      song.rebuild_code!
      delete song_path(song)
      expect(Setting.songs_root.join("starlight")).not_to exist
      expect(Song.exists?(song.id)).to be(false)
      expect(response).to redirect_to(root_path)
      expect(Player).not_to have_received(:stop)
    end

    it "stops the song first when it is playing" do
      NowPlaying.current_song_id = song.id
      delete song_path(song)
      expect(Player).to have_received(:stop)
      expect(NowPlaying.current_song_id).to be_nil
    end

    it "deletes even when Sonic Pi is closed" do
      NowPlaying.current_song_id = song.id
      allow(Player).to receive(:stop).and_raise(Player::NotRunning)
      delete song_path(song)
      expect(Song.exists?(song.id)).to be(false)
    end
  end

  describe "rebuilding the code" do
    let(:song) { create(:song, :ready, code: "play 60") }

    it "is offered on the song" do
      get song_path(song)
      expect(response.body).to include(song_code_path(song))
    end

    it "builds the code anew from the current groove" do
      post song_code_path(song)
      expect(song.reload.code).to include("live_loop :conductor")
      expect(response).to redirect_to(song_path(song))
    end
  end

  describe "the songs folder" do
    it "tells where the song lies" do
      song = create(:song, :ready)
      song.rebuild_code!
      get song_path(song)
      expect(response.body).to include(Setting.songs_root.join("starlight").to_s)
      expect(response.body).not_to include("Ins Repo")
    end
  end

  describe "the loop switch" do
    let(:song) { create(:song, :ready) }
    let(:stream) { {"Accept" => "text/vnd.turbo-stream.html"} }

    before { allow(Player).to receive(:loop) { |on| Player.looping = on } }
    after { Player.looping = false }

    it "sits with the footswitches, on key L" do
      get song_path(song)
      expect(response.body).to include("Endlos", 'data-hotkey="l"', song_loop_path(song))
    end

    it "switches the loop on and lights its lamp" do
      patch song_loop_path(song), params: {on: "1"}, headers: stream
      expect(Player).to have_received(:loop).with(true)
      expect(response.body).to include("loop_switch", "lamp-on")
    end

    it "switches it off again" do
      Player.looping = true
      patch song_loop_path(song), params: {on: "0"}, headers: stream
      expect(Player).to have_received(:loop).with(false)
      expect(response.body).not_to include("lamp-on")
    end
  end

  describe "recording a WAV" do
    let(:song) { create(:song, :ready) }

    after { FileUtils.rm_f(song.recording_path) }

    it "offers to record" do
      get song_path(song)
      expect(response.body).to include("WAV aufnehmen", song_recording_path(song))
    end

    it "starts the recording and says it is on" do
      expect { post song_recording_path(song) }.to have_enqueued_job(RecordSongJob).with(song)
      expect(song.reload.recording_status).to eq("pending")
      follow_redirect!
      expect(response.body).to include("Nimmt auf")
    end

    it "hands out the take once it is there" do
      song.recording_path.dirname.mkpath
      song.recording_path.write("RIFF")
      song.update!(recording_status: "ready")
      get song_path(song)
      expect(response.body).to include("Starlight.wav")
      get song_recording_path(song)
      expect(response.headers["Content-Disposition"]).to include("attachment", "Starlight.wav")
      expect(response.body).to eq("RIFF")
    end

    it "has nothing to hand out before there is a take" do
      get song_recording_path(song)
      expect(response).to have_http_status(:not_found)
    end

    it "goes when the song is deleted" do
      song.recording_path.dirname.mkpath
      song.recording_path.write("RIFF")
      allow(Player).to receive(:stop)
      delete song_path(song)
      expect(song.recording_path).not_to exist
    end
  end
end
