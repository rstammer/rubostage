require "rails_helper"

RSpec.describe "Chatting about a song", type: :request do
  include ActiveJob::TestHelper

  let(:song) { create(:song, :ready) }

  it "sits in the editor, with the conversation so far" do
    song.messages.create!(role: "user", body: "Klingt der Bass zu laut?")
    get edit_song_path(song)
    expect(response.body).to include('id="chat"', 'name="message[body]"', "Klingt der Bass zu laut?")
  end

  it "takes a question and asks Claude for the answer" do
    expect {
      post song_messages_path(song), params: {message: {body: "Mehr Druck im Chorus?"}}, as: :turbo_stream
    }.to change(song.messages, :count).by(1).and have_enqueued_job(SongChatJob).with(song)
    expect(song.messages.last).to have_attributes(role: "user", body: "Mehr Druck im Chorus?")
    expect(response.media_type).to eq(Mime[:turbo_stream])
  end

  it "ignores an empty question" do
    expect {
      post song_messages_path(song), params: {message: {body: "  "}}, as: :turbo_stream
    }.not_to change(SongMessage, :count)
  end

  it "goes back to the editor without Turbo" do
    post song_messages_path(song), params: {message: {body: "Hallo"}}
    expect(response).to redirect_to(edit_song_path(song, anchor: "chat"))
  end

  it "goes when the song goes" do
    song.messages.create!(role: "user", body: "Hallo")
    expect { song.destroy }.to change(SongMessage, :count).by(-1)
  end
end
