require "rails_helper"

RSpec.describe Groove do
  let(:sheet) do
    SongSheet.from_h(
      "title" => "Starlight", "artist" => "Muse", "key" => "B", "bpm" => 122,
      "sections" => [
        {"name" => "Verse", "bars" => [["B"], ["C#m"], ["G#m"], ["E"]]},
        {"name" => "Bridge", "bars" => [["G#m"], ["E"], ["B"], ["F#", "F#/A#"]]}
      ],
      "form" => ["Verse", "Bridge", "Verse"]
    )
  end

  let(:groove) { described_class.new(sheet, song_id: 7, osc_port: 4570) }
  let(:code) { groove.code }

  it "sets the tempo above the loops" do
    expect(code.index("use_bpm 122")).to be < code.index("live_loop :")
  end

  it "is code Sonic Pi will accept" do
    expect(CodeCheck.problems(code)).to be_empty
    expect(CodeCheck.problems(described_class.new(sheet).code)).to be_empty
  end

  it "plays every bar of the form, split chords two beats each" do
    expect(groove.timeline.map { |step| step[:beats] }).to eq([4, 4, 4, 4, 4, 4, 4, 2, 2, 4, 4, 4, 4])
  end

  it "puts the bass note of a slash chord in the bass" do
    bridge_end = groove.timeline[8]
    expect(bridge_end[:bass]).to eq(ChordSymbol.parse("F#/A#").bass_note)
  end

  it "writes each section once and the form as indexes into them" do
    expect(code).to include("form = [0, 1, 0]")
    expect(code.scan("# Verse: B").size).to eq(1)
  end

  it "knows where each form position starts on the stage's chord count" do
    expect(code).to include("offsets = [0, 4, 9]")
  end

  it "has drums, bass, comp and pad, all following the conductor" do
    %w[drums bass comp pad].each do |voice|
      expect(code).to match(/live_loop :#{voice} do\n  pos = sync\(:section\)\[0\]/)
    end
  end

  it "defines the conductor last, so every voice hears its first cue" do
    expect(code.rindex("live_loop")).to eq(code.index("live_loop :conductor"))
  end

  it "takes the stage's commands at the next section boundary" do
    expect(code).to include("get[:stage_cmd]", ":repeat", ":jump", ":end")
  end

  it "closes on the key's chord" do
    expect(code).to include("final = [#{ChordSymbol.parse("B").bass_note}, #{ChordSymbol.parse("B").voicing.inspect}]")
  end

  describe "telling the stage where it is" do
    it "sends every chord change and the ending" do
      expect(code).to include('use_osc "127.0.0.1", 4570', 'osc "/stage/step", 7, offsets[pos] + index', 'osc "/stage/step", 7, -1')
    end

    it "stays quiet about it without a song id" do
      expect(described_class.new(sheet).code).not_to include("use_osc")
    end
  end

  describe "with an arrangement" do
    let(:arrangement) do
      Arrangement.from_h({
        "sounds" => {"bass" => "tb303", "comp" => "pulse", "pad" => "dark_ambience", "distorted" => true},
        "sections" => {"Verse" => {"energy" => 3, "kick" => "x...x...x...x..."}}
      }, sheet)
    end
    let(:arranged) { described_class.new(sheet, song_id: 7, osc_port: 4570, arrangement: arrangement) }

    it "plays the arranged patterns and sounds" do
      expect(arranged.code).to include("use_synth :tb303", "use_synth :pulse", "use_synth :dark_ambience", "with_fx :distortion")
      expect(arranged.code).to include("[0, 4, 8, 12]")
    end

    it "is code Sonic Pi will accept" do
      expect(CodeCheck.problems(arranged.code)).to be_empty
      expect(CodeCheck.problems(arranged.voices_code)).to be_empty
    end

    it "can swap only the voices, leaving the conductor and its place in the form" do
      voices = arranged.voices_code
      expect(voices).to include("live_loop :drums", "live_loop :bass", "live_loop :comp", "live_loop :pad")
      expect(voices).not_to include("live_loop :conductor", "set :stage_next", "4.times do")
    end
  end
end
