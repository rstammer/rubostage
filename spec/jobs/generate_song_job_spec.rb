require "rails_helper"

RSpec.describe GenerateSongJob do
  let(:song) { create(:song) }
  let(:sheet) do
    SongSheet.from_h(
      "title" => "Starlight", "artist" => "Muse", "key" => "B", "bpm" => 122,
      "sections" => [{"name" => "Verse", "bars" => [["B"], ["C#m"], ["G#m"], ["E"]]}],
      "form" => ["Verse"]
    )
  end
  let(:writer) { instance_double(SheetWriter, call: sheet) }

  before do
    allow(SheetWriter).to receive(:new).and_return(writer)
    allow(Player).to receive(:play)
  end

  it "writes sheet and groove onto the song" do
    described_class.perform_now(song)
    song.reload
    expect(song.status).to eq("ready")
    expect(song.title).to eq("Starlight")
    expect(song.bpm).to eq(122)
    expect(song.sheet["form"]).to eq(["Verse"])
    expect(song.code).to include("use_bpm 122")
  end

  it "starts playing right away" do
    described_class.perform_now(song)
    expect(Player).to have_received(:play).with(song.reload.code)
  end

  it "keeps the song ready when Sonic Pi is not running" do
    allow(Player).to receive(:play).and_raise(Player::NotRunning)
    described_class.perform_now(song)
    expect(song.reload.status).to eq("ready")
  end

  it "marks the song failed when no sheet comes back" do
    allow(writer).to receive(:call).and_raise(SongSheet::Invalid, "no JSON in the answer")
    described_class.perform_now(song)
    song.reload
    expect(song.status).to eq("failed")
    expect(song.error).to include("no JSON")
  end
end
