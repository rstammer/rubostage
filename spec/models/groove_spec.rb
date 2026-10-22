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

  it "plays a held bar as the chord before it, twice as long" do
    held = SongSheet.from_h(sheet.to_h.merge("sections" => [{"name" => "Verse", "bars" => [["B"], [], ["E"]]}], "form" => ["Verse"]))
    expect(described_class.new(held).timeline.map { |step| [step[:chord], step[:beats]] }).to eq([["B", 8], ["E", 4]])
  end

  it "plays two-beat bars as half as long, with the patterns running on" do
    half = SongSheet.from_h(sheet.to_h.merge("beats" => 2, "sections" => [{"name" => "Verse", "bars" => [["C"], ["Am"], ["Em"], []]}], "form" => ["Verse"]))
    code = described_class.new(half).code
    expect(described_class.new(half).timeline.map { |step| step[:beats] }).to eq([2, 2, 4])
    expect(CodeCheck.problems(code)).to be_empty
  end

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

  it "starts the form again at its end while the loop is on" do
    expect(code).to include("following = (get[:stage_loop] ? 0 : -1) if following >= form.length")
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

    it "plays power chords on one detuned saw through distortion" do
      expect(arranged.code).to include("use_synth :dsaw", "with_fx :distortion")
      expect(arranged.code).not_to include("pan: -0.7", "use_synth :saw\n")
    end

    it "leaves headroom at full energy" do
      expect(arranged.code).to include("levels = [0, 0.4, 0.6, 0.8]")
    end

    it "swings the offbeats with time_warp" do
      expect(arranged.code).to include("time_warp late do")
    end

    it "plays a tom fill in the last bar when a section asks for one" do
      expect(arranged.code).to include("drum_tom_hi_hard", "drum_tom_lo_hard")
    end

    it "crashes into loud sections" do
      expect(arranged.code).to include("drum_cymbal_hard")
    end

    it "can swap only the voices, leaving the conductor and its place in the form" do
      voices = arranged.voices_code
      expect(voices).to include("live_loop :drums", "live_loop :bass", "live_loop :comp", "live_loop :pad")
      expect(voices).not_to include("live_loop :conductor", "set :stage_next", "4.times do")
    end
  end

  describe "with riffs" do
    let(:verse_tab) do
      <<~TAB
        e|----------------|
        B|----------------|
        G|----------------|
        D|----------------|
        A|--------2-------|
        E|0-x-0-------3---|
      TAB
    end
    let(:riffs) { RiffTrack.from_h({"tone" => "clean", "tabs" => {"Verse" => verse_tab}}) }
    let(:with_riffs) { described_class.new(sheet, song_id: 7, osc_port: 4570, riffs: riffs) }

    it "writes each section's riff as its length, swing, loudness and [step, pitch, steps held]" do
      expect(with_riffs.code).to include("[16, 0, 0.6, [[0, 40, 2], [2, 40, 0], [4, 40, 8], [8, 47, 8], [12, 43, 4]]], # Verse")
      expect(with_riffs.code).to include("nil, # Bridge")
    end

    it "plays them in a voice of its own that follows the conductor" do
      expect(with_riffs.code).to match(/live_loop :riff do\n  pos = sync\(:section\)\[0\]/)
      expect(with_riffs.code).to include("use_synth :pluck")
    end

    it "plays crunchy riffs on a detuned saw through distortion" do
      crunchy = RiffTrack.from_h({"tabs" => {"Verse" => verse_tab}})
      code = described_class.new(sheet, riffs: crunchy).code
      expect(code[code.index("live_loop :riff")..]).to include("use_synth :dsaw", "with_fx :distortion")
    end

    it "swings with the arrangement" do
      arrangement = Arrangement.from_h({"sections" => {"Verse" => {"groove" => "shuffle"}}}, sheet)
      code = described_class.new(sheet, riffs: riffs, arrangement: arrangement).code
      expect(code).to include("[16, #{DrumGroove.default_swing(:shuffle)}, 0.6, [[0, 40, 2]")
    end

    it "gets as loud as the arrangement's energy for the section" do
      arrangement = Arrangement.from_h({"sections" => {"Verse" => {"energy" => 1}}}, sheet)
      code = described_class.new(sheet, riffs: riffs, arrangement: arrangement).code
      expect(code).to include("[16, 0, 0.4, [[0, 40, 2]")
    end

    it "turns crunch down after the distortion, which evens out whatever goes in" do
      crunchy = RiffTrack.from_h({"tabs" => {"Verse" => verse_tab}})
      code = described_class.new(sheet, riffs: crunchy).code
      expect(code[code.index("live_loop :riff")..]).to include("with_fx :distortion, distort: 0.8, amp: 0.3 * riff[2]")
    end

    it "plays clean riffs as loud as the section" do
      voice = with_riffs.code[with_riffs.code.index("live_loop :riff")..]
      expect(voice).to include("with_fx :reverb, room: 0.4, mix: 0.2, amp: riff[2]")
    end

    it "is code Sonic Pi will accept, also when swapped in" do
      expect(CodeCheck.problems(with_riffs.code)).to be_empty
      expect(with_riffs.voices_code).to include("live_loop :riff")
    end

    it "leaves the riff voice out when there are no tabs" do
      expect(described_class.new(sheet, riffs: RiffTrack.from_h({})).code).not_to include("live_loop :riff")
    end
  end
end
