require "rails_helper"

RSpec.describe NowPlaying do
  let(:song) do
    create(:song, :ready, sheet: {
      "title" => "Starlight", "artist" => "Muse", "key" => "B", "bpm" => 122,
      "sections" => [
        {"name" => "Verse", "bars" => [["B"], ["C#m"]]},
        {"name" => "Bridge", "bars" => [["G#m", "E"]]}
      ],
      "form" => ["Verse", "Bridge"]
    })
  end

  it "names the chord, the next one and the section" do
    now = described_class.new(song, 1)
    expect(now.chord).to eq("C#m")
    expect(now.next_chord).to eq("G#m")
    expect(now.section).to eq("Verse")
  end

  it "wraps around to the start after the last chord" do
    now = described_class.new(song, 3)
    expect(now.chord).to eq("E")
    expect(now.next_chord).to eq("B")
    expect(now.section).to eq("Bridge")
  end

  it "renders a panel that marks the current chord on the sheet" do
    html = ApplicationController.render(partial: "songs/now", locals: {now: described_class.new(song, 2)})
    expect(html).to include("G#m", "dann", "E", "Bridge", "#chord-1-0")
  end
end
