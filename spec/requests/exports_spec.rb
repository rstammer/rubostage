require "rails_helper"

RSpec.describe "Exports", type: :request do
  around do |example|
    Dir.mktmpdir do |root|
      Rails.application.config.x.songs_root = Pathname(root)
      @root = Pathname(root)
      example.run
    ensure
      Rails.application.config.x.songs_root = nil
    end
  end

  let(:song) { create(:song, :ready) }

  it "writes the song into the repo and says where" do
    post song_export_path(song)
    expect(@root.join("starlight/live.rb")).to exist
    expect(response).to redirect_to(song_path(song))
    expect(flash[:notice]).to include("songs/starlight")
  end

  it "says so instead of overwriting a hand-written song" do
    @root.join("starlight").mkpath
    @root.join("starlight/live.rb").write("play 60\n")
    post song_export_path(song)
    expect(flash[:alert]).to include("songs/starlight/live.rb", "von Hand")
    expect(@root.join("starlight/live.rb").read).to eq("play 60\n")
  end

  it "offers the button on a ready song" do
    get song_path(song)
    expect(response.body).to include(song_export_path(song))
  end
end
