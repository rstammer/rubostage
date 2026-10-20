require "rails_helper"

RSpec.describe "Controls", type: :request do
  before do
    allow(SonicPiApp).to receive(:launch)
    allow(SonicPiApp).to receive(:state).and_return(:off)
  end

  after { NowPlaying.current_song_id = NowPlaying.last_step_at = nil }

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
end
