require "rails_helper"

RSpec.describe Groove do
  let(:sheet) do
    SongSheet.from_h(
      "title" => "Starlight", "artist" => "Muse", "key" => "B", "bpm" => 122,
      "sections" => [
        {"name" => "Verse", "bars" => [["B"], ["C#m"], ["G#m"], ["E"]]},
        {"name" => "Bridge", "bars" => [["G#m"], ["E"], ["B"], ["F#", "F#/A#"]]}
      ],
      "form" => ["Verse", "Bridge"]
    )
  end

  let(:code) { described_class.new(sheet).code }

  it "sets the tempo above the loops" do
    expect(code.index("use_bpm 122")).to be < code.index("live_loop :")
  end

  it "is code Sonic Pi will accept" do
    expect(CodeCheck.problems(code)).to be_empty
  end

  it "plays every bar of the form, split chords two beats each" do
    expect(described_class.new(sheet).timeline.map { |step| step[:beats] }).to eq([4, 4, 4, 4, 4, 4, 4, 2, 2])
  end

  it "puts the bass note of a slash chord in the bass" do
    last = described_class.new(sheet).timeline.last
    expect(last[:bass]).to eq(ChordSymbol.parse("F#/A#").bass_note)
  end

  it "has drums, bass and chords" do
    expect(code).to include("live_loop :drums", "live_loop :bass", "live_loop :pad")
  end

  it "defines the clock last, so every voice hears the first cue" do
    expect(code.rindex("live_loop")).to eq(code.index("live_loop :clock"))
  end

  it "loops the whole form in one pass" do
    expect(code).to include("sleep 32")
  end

  describe "telling the stage where it is" do
    let(:code) { described_class.new(sheet, song_id: 7, osc_port: 4570).code }

    it "sends every chord change to the stage" do
      expect(code).to include('use_osc "127.0.0.1", 4570', 'osc "/stage/step", 7, index')
    end

    it "is still code Sonic Pi will accept" do
      expect(CodeCheck.problems(code)).to be_empty
    end

    it "stays quiet about it without a song id" do
      expect(described_class.new(sheet).code).not_to include("use_osc")
    end
  end
end
