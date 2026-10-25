require "rails_helper"

RSpec.describe SongTools::EditSheet do
  let(:song) { create(:song, :ready, arrangement: {"sections" => {"Verse" => {"energy" => 3}}}, arrangement_status: "ready") }

  before { allow(Player).to receive(:upgrade) }

  def edit(args) = described_class.new.call(song, args)

  it "changes only what it is given and says what changed" do
    result = edit("key" => "C", "bpm" => 100)
    song.reload
    expect([song.key, song.bpm, song.lead_sheet.section("Verse").chart]).to eq(["C", 100, "B | C#m | G#m | E"])
    expect(result).to match(/geändert/i)
  end

  it "sets the chords of a section and adds new sections" do
    edit("sections" => [{"name" => "Verse", "chords" => "Em | A | Em | E"}, {"name" => "Chorus", "chords" => "C | G"}],
      "form" => ["Verse", "Chorus", "Verse"])
    sheet = song.reload.lead_sheet
    expect(sheet.section("Verse").chart).to eq("Em | A | Em | E")
    expect(sheet.form).to eq(%w[Verse Chorus Verse])
  end

  it "keeps the band's part of a section" do
    edit("sections" => [{"name" => "Verse", "chords" => "Em | A"}])
    expect(song.reload.full_arrangement.section("Verse").energy).to eq(3)
  end

  it "tells the model whether the change is heard right away" do
    expect(edit("key" => "C")).to include("not playing")
    NowPlaying.current_song_id = song.id
    expect(edit("bpm" => 100)).to include("started again")
    expect(edit("key" => "D")).to include("next part")
  ensure
    NowPlaying.current_song_id = nil
  end

  it "records the change, so it can be taken back" do
    expect { edit("bpm" => 100, "summary" => "Langsamer") }.to change(song.changes_made, :count).by(1)
    expect(song.changes_made.last.summary).to eq("Langsamer")
  end

  it "refuses what the editor would refuse, and keeps the song" do
    expect { edit("sections" => [{"name" => "Verse", "chords" => "B | Hm"}]) }.to raise_error(SongTools::Error)
    expect(song.reload.lead_sheet.section("Verse").chart).to eq("B | C#m | G#m | E")
    expect(song.changes_made).to be_empty
  end
end
