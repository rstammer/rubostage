require "rails_helper"

RSpec.describe SongTools::EditBand do
  let(:song) { create(:song, :ready, arrangement: {"sounds" => {"bass" => "fm"}, "sections" => {"Verse" => {"energy" => 2}}}, arrangement_status: "ready") }

  before { allow(Player).to receive(:upgrade) }

  def edit(args) = described_class.new.call(song, args)

  it "changes the sounds and a section's patterns, keeping the rest" do
    edit("sounds" => {"bass" => "tb303"}, "sections" => [{"name" => "Verse", "bass" => "1..1..5.8..1..5."}])
    arrangement = song.reload.full_arrangement
    expect(arrangement.sounds[:bass]).to eq(:tb303)
    expect(arrangement.section("Verse").to_h["bass"]).to eq("1..1..5.8..1..5.")
    expect(arrangement.section("Verse").energy).to eq(2)
    expect(song.code).to include("use_synth :tb303")
  end

  it "gives a song without a band one" do
    song.update!(arrangement: nil, arrangement_status: "none")
    edit("sections" => [{"name" => "Verse", "energy" => 3}])
    expect(song.reload.arrangement_status).to eq("ready")
    expect(song.full_arrangement.section("Verse").energy).to eq(3)
  end

  it "refuses sounds it cannot play and patterns of the wrong length" do
    expect { edit("sounds" => {"bass" => "kazoo"}) }.to raise_error(SongTools::Error, /kazoo/)
    expect { edit("sections" => [{"name" => "Verse", "bass" => "1.1"}]) }.to raise_error(SongTools::Error, /16/)
    expect { edit("sections" => [{"name" => "Bridge", "energy" => 1}]) }.to raise_error(SongTools::Error, /Bridge/)
    expect(song.changes_made).to be_empty
  end
end
