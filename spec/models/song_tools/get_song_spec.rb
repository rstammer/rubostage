require "rails_helper"

RSpec.describe SongTools::GetSong do
  let(:song) do
    create(:song, :ready, lyrics: "Far away, this ship",
      arrangement: {"sounds" => {"bass" => "tb303"}, "sections" => {"Verse" => {"energy" => 3}}}, arrangement_status: "ready")
  end

  it "hands over the sheet, the band and the riffs as JSON, without the lyrics" do
    data = JSON.parse(described_class.new.call(song, {}))
    expect(data).to include("title" => "Starlight", "key" => "B", "bpm" => 122, "beats" => 4, "form" => ["Verse"])
    expect(data["sections"].first).to include("name" => "Verse", "chords" => "B | C#m | G#m | E")
    expect(data.dig("band", "sounds", "bass")).to eq("tb303")
    expect(data.dig("band", "sections", "Verse", "energy")).to eq(3)
    expect(data.to_s).not_to include("this ship")
  end

  it "describes itself for any client" do
    expect(described_class.tool_name).to eq("get_song")
    expect(described_class.input_schema).to include(type: "object")
    expect(SongTools.all.map(&:activity)).to all(be_present)
  end
end
