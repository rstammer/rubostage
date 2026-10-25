require "rails_helper"

RSpec.describe "The sidebars", type: :request do
  let!(:song) { create(:song, :ready, lyrics: "Far away, this ship is taking me") }
  let!(:other) { create(:song, :ready, title: "Traveller", artist: "Chris Stapleton") }

  before { NowPlaying.started_song_id = nil }

  it "frame every page: the songs and the text on the left, the chat on the right" do
    [root_path, song_path(song), edit_song_path(song), new_song_path, settings_path].each do |path|
      get path
      expect(response.body).to include('id="sidebar_left"', 'id="sidebar_right"', 'id="sidebar_songs"', 'id="lyrics"'), path
    end
  end

  it "lists the repertoire on the left and marks the song in front" do
    get song_path(song)
    expect(response.body).to include(song_path(other))
    expect(response.body).to match(/<a aria-current="page"[^>]*href="#{song_path(song)}"/)
  end

  it "shows the text of the song in front" do
    get edit_song_path(song)
    expect(response.body).to include("this ship is taking me")
  end

  it "talks about the song in front" do
    song.messages.create!(role: "user", body: "Mehr Druck?")
    get song_path(song)
    expect(response.body).to include('id="chat"', song_messages_path(song), "Mehr Druck?")
  end

  it "talks about the song last started on a page without a song" do
    NowPlaying.started_song_id = other.id
    get root_path
    expect(response.body).to include(song_messages_path(other))
    expect(response.body).not_to include(song_messages_path(song))
  end

  it "asks for a song when there is none to talk about" do
    get root_path
    expect(response.body).not_to include('name="message[body]"')
    expect(response.body).to include("Wähl einen Song")
  end

  it "stays drawn in where it was drawn in" do
    cookies[:sidebar_left] = "closed"
    get root_path
    expect(response.body).to match(/id="sidebar_left"[^>]*data-state="closed"/)
    expect(response.body).to match(/id="sidebar_right"[^>]*data-state="open"/)
  end

  it "opens on the tab chosen last" do
    cookies[:sidebar_tab] = "text"
    get root_path
    expect(response.body).to include('data-sidebar-tab-value="text"')
  end
end
