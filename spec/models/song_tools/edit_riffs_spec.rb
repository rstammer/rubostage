require "rails_helper"

RSpec.describe SongTools::EditRiffs do
  let(:song) { create(:song, :ready) }
  let(:tab) { "e|----------------|\nB|----------------|\nG|----------------|\nD|----------------|\nA|----------------|\nE|0---0---3---5---|\n" }

  before { allow(Player).to receive(:upgrade) }

  def edit(args) = described_class.new.call(song, {"summary" => "Riffs"}.merge(args))

  it "sets how the riffs sound and the tuning they are fretted in" do
    edit("tone" => "clean", "tuning" => "drop_d")
    expect(song.reload.riffs).to have_attributes(tone: "clean", tuning: "drop_d")
    expect(song.changes_made.count).to eq(1)
  end

  it "tabs a riff into a section and takes one out again" do
    edit("sections" => [{"name" => "Verse", "tab" => tab}])
    expect(song.reload.riffs.tab("Verse")).to be_present
    edit("sections" => [{"name" => "Verse", "tab" => ""}])
    expect(song.reload.riffs.tab("Verse")).to be_nil
  end

  it "refuses a tone or tuning it does not know" do
    expect { edit("tone" => "fuzz") }.to raise_error(SongTools::Error, /fuzz/)
    expect { edit("tuning" => "open_g") }.to raise_error(SongTools::Error, /open_g/)
    expect { edit("sections" => [{"name" => "Bridge", "tab" => tab}]) }.to raise_error(SongTools::Error, /Bridge/)
  end
end
