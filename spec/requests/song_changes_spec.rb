require "rails_helper"

RSpec.describe "Taking back what Claude changed", type: :request do
  let(:song) { create(:song, :ready) }

  before { allow(Player).to receive(:upgrade) }

  it "shows each change in the chat with a button to take it back" do
    SongChange.record(song, "Tempo auf 100") { song.update!(bpm: 100) }
    get song_path(song)
    expect(response.body).to include("Tempo auf 100", "Rückgängig")
  end

  it "takes the change back" do
    change = SongChange.record(song, "Tempo auf 100") { song.update!(bpm: 100) }
    post undo_song_change_path(song, change)
    expect(song.reload.bpm).to eq(122)
    expect(change.reload).to be_undone
    expect(response).to redirect_to(song_path(song))
  end
end
