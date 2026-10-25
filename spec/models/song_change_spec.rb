require "rails_helper"

RSpec.describe SongChange do
  let(:song) { create(:song, :ready) }

  before { allow(Player).to receive(:upgrade) }

  it "remembers the song as it was before a change" do
    change = described_class.record(song, "Tempo auf 100") { song.update!(bpm: 100) }
    expect(change.summary).to eq("Tempo auf 100")
    expect(change.before["bpm"]).to eq(122)
    expect(song.reload.bpm).to eq(100)
  end

  it "records nothing when the change fails" do
    expect {
      described_class.record(song, "kaputt") { raise SongTools::Error, "nope" }
    }.to raise_error(SongTools::Error)
    expect(described_class.count).to eq(0)
  end

  it "takes a change back and builds the code again" do
    change = described_class.record(song, "Tempo auf 100") { song.update!(bpm: 100, sheet: song.sheet.merge("bpm" => 100)) }
    change.undo!
    song.reload
    expect(song.bpm).to eq(122)
    expect(song.lead_sheet.bpm).to eq(122)
    expect(song.code).to include("use_bpm 122")
    expect(change.reload).to be_undone
  end

  it "takes back what came after it too, since that was built on it" do
    first = described_class.record(song, "Tempo 100") { song.update!(bpm: 100) }
    second = described_class.record(song, "Tempo 90") { song.update!(bpm: 90) }
    first.undo!
    expect(song.reload.bpm).to eq(122)
    expect(second.reload).to be_undone
  end

  it "swaps the change into the song while it plays" do
    NowPlaying.current_song_id = song.id
    described_class.record(song, "Energie") { song.update!(arrangement: {"sections" => {}}, arrangement_status: "ready") }
    expect(Player).to have_received(:upgrade)
  ensure
    NowPlaying.current_song_id = nil
  end
end
