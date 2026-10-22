require "rails_helper"

RSpec.describe "Controls", type: :request do
  before do
    allow(SonicPiApp).to receive(:launch)
    allow(SonicPiApp).to receive(:state).and_return(:off)
  end

  after { NowPlaying.current_song_id = NowPlaying.last_step_at = NowPlaying.started_song_id = nil }

  def state(value)
    allow(SonicPiApp).to receive(:state).and_return(value)
  end

  it "sits on every page, with a start button while Sonic Pi is off" do
    get root_path
    expect(response.body).to include('id="controls"', "Starten", sonic_pi_path)
  end

  it "keeps asking for the latest state" do
    get controls_path
    expect(response.body).to include('data-controller="poll"', controls_path)
  end

  it "launches Sonic Pi and goes back to the panel" do
    post sonic_pi_path
    expect(SonicPiApp).to have_received(:launch)
    expect(response).to redirect_to(controls_path)
  end

  it "does not launch a second one" do
    state(:starting)
    post sonic_pi_path
    expect(SonicPiApp).not_to have_received(:launch)
  end

  it "blinks while Sonic Pi starts" do
    state(:starting)
    get controls_path
    expect(response.body).to include("lamp-blink")
    expect(response.body).not_to include("Starten")
  end

  it "names the song that plays" do
    state(:ready)
    song = create(:song, :ready)
    NowPlaying.current_song_id = song.id
    NowPlaying.last_step_at = Time.current
    get controls_path
    expect(response.body).to include("Starlight", song_path(song))
  end

  it "forgets the song when it is stopped" do
    state(:ready)
    allow(Player).to receive(:stop)
    NowPlaying.current_song_id = create(:song, :ready).id
    delete playback_path
    expect(NowPlaying.current_song_id).to be_nil
  end

  describe "the transport bar" do
    let(:song) { create(:song, :ready) }

    it "is not there before a song was started" do
      state(:ready)
      get transport_path
      expect(response.body).not_to include("transport_bar")
    end

    it "remembers the song started and offers its footswitches on every page" do
      state(:ready)
      allow(Player).to receive(:play)
      post song_playback_path(song)
      get edit_song_path(create(:song, :ready))
      expect(response.body).to include('id="transport_bar"', "Starlight", song_playback_path(song), playback_path,
        song_command_path(song, kind: "next"), song_command_path(song, kind: "end"), song_command_path(song, kind: "repeat"),
        "bar_loop_switch")
    end

    it "is a row of its own that keeps asking for the latest state" do
      state(:ready)
      NowPlaying.started_song_id = song.id
      get transport_path
      expect(response.body).to include('<turbo-frame id="transport"', 'id="transport_bar"', 'data-controller="poll"', transport_path)
    end

    it "answers play and stop from the bar with the bar, not with a whole page" do
      state(:ready)
      allow(Player).to receive(:play)
      allow(Player).to receive(:stop)
      frame = {"Turbo-Frame" => "transport"}
      post song_playback_path(song), headers: frame
      expect(response).to redirect_to(transport_path)
      delete playback_path, headers: frame
      expect(response).to redirect_to(transport_path)
    end

    it "stays after a stop, so the song can start again from anywhere" do
      state(:ready)
      allow(Player).to receive(:stop)
      NowPlaying.started_song_id = song.id
      delete playback_path
      get transport_path
      expect(response.body).to include('id="transport_bar"')
    end

    it "goes with the song when it is deleted" do
      state(:ready)
      allow(Player).to receive(:stop)
      NowPlaying.started_song_id = song.id
      delete song_path(song)
      expect(NowPlaying.started_song_id).to be_nil
    end

    it "is where the loop switch and commands answer too" do
      state(:ready)
      allow(Player).to receive(:loop)
      allow(Player).to receive(:command)
      stream = {"Accept" => "text/vnd.turbo-stream.html"}
      patch song_loop_path(song), params: {on: "1"}, headers: stream
      expect(response.body).to include('target="loop_switch"', 'target="bar_loop_switch"')
      post song_command_path(song), params: {kind: "next"}, headers: stream
      expect(response.body).to include('target="queued"', 'target="bar_queued"')
    end
  end
end
