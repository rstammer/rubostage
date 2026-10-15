require "rails_helper"

RSpec.describe "Commands", type: :request do
  let(:song) { create(:song, :ready) }
  let(:stream) { {"Accept" => "text/vnd.turbo-stream.html"} }

  before { allow(Player).to receive(:command) }

  it "queues a repeat and says so" do
    post song_command_path(song), params: {kind: "repeat"}, headers: stream
    expect(Player).to have_received(:command).with(:repeat, nil)
    expect(response.body).to include("queued", "wiederholen")
  end

  it "queues a jump to a position of the form" do
    post song_command_path(song), params: {kind: "jump", position: "0"}, headers: stream
    expect(Player).to have_received(:command).with(:jump, 0)
    expect(response.body).to include("Verse")
  end

  it "refuses a jump outside the form" do
    post song_command_path(song), params: {kind: "jump", position: "9"}, headers: stream
    expect(response).to have_http_status(:unprocessable_content)
    expect(Player).not_to have_received(:command)
  end

  it "refuses an unknown command" do
    post song_command_path(song), params: {kind: "explode"}, headers: stream
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "says so when Sonic Pi is not running" do
    allow(Player).to receive(:command).and_raise(Player::NotRunning)
    post song_command_path(song), params: {kind: "next"}, headers: stream
    expect(response.body).to include("Sonic Pi läuft nicht")
  end
end
