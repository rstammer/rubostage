require "rails_helper"

RSpec.describe SongTools::Rearrange do
  include ActiveJob::TestHelper

  let(:song) { create(:song, :ready) }

  it "has the band written anew in the background, with the wish, as an undoable change" do
    result = described_class.new.call(song, {"wish" => "mehr Funk", "summary" => "Funkiger"})
    expect(ArrangeSongJob).to have_been_enqueued.with(song, wish: "mehr Funk", summary: "Funkiger")
    expect(song.reload.arrangement_status).to eq("pending")
    expect(result).to match(/minute/i)
  end

  it "does not start a second one while one is being written" do
    song.update!(arrangement_status: "pending")
    expect { described_class.new.call(song, {"summary" => "x"}) }.to raise_error(SongTools::Error, /already/)
  end
end
