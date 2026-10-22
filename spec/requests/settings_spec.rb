require "rails_helper"

RSpec.describe "Settings", type: :request do
  around do |example|
    Dir.mktmpdir { |dir| @dir = Pathname(dir) and example.run }
  end

  it "is reached from the control bar" do
    get root_path
    expect(response.body).to include(settings_path)
  end

  it "shows the songs folder in use" do
    get settings_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(Setting.songs_root.to_s, 'name="songs_root"')
  end

  it "stores a new songs folder and puts every song there" do
    create(:song, :ready)
    patch settings_path, params: {songs_root: @dir.to_s}
    expect(@dir.join("starlight/live.rb")).to exist
    expect(Setting.songs_root).to eq(@dir)
    expect(response).to redirect_to(settings_path)
  end

  it "says what is wrong with a folder and keeps the old one" do
    before = Setting.songs_root
    patch settings_path, params: {songs_root: @dir.join("missing").to_s}
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("gibt es nicht", @dir.join("missing").to_s)
    expect(Setting.songs_root).to eq(before)
  end
end
