require "rails_helper"

RSpec.describe RiffTrack do
  let(:verse_tab) do
    <<~TAB
      e|----------------|
      B|----------------|
      G|----------------|
      D|----------------|
      A|----------------|
      E|0---0---3---5---|
    TAB
  end

  it "reads the tab of each section in the song's tuning" do
    track = described_class.from_h({"tuning" => "drop_d", "tabs" => {"Verse" => verse_tab}})
    expect(track.tab("Verse").notes.first).to eq([0, 38, 4])
    expect(track.tab("Chorus")).to be_nil
  end

  it "plays crunchy in standard tuning unless told otherwise" do
    track = described_class.from_h({})
    expect([track.tuning, track.tone]).to eq(%w[standard crunch])
  end

  it "falls back to the defaults for tunings and tones it does not know" do
    track = described_class.from_h({"tuning" => "open_g", "tone" => "kazoo"})
    expect([track.tuning, track.tone]).to eq(%w[standard crunch])
  end

  it "knows whether there is anything to play" do
    expect(described_class.from_h({"tabs" => {"Verse" => " "}})).to be_empty
    expect(described_class.from_h({"tabs" => {"Verse" => verse_tab}})).not_to be_empty
  end

  it "names the section when a tab does not read" do
    track = described_class.from_h({"tabs" => {"Chorus" => "e|---|"}})
    expect { track.validate! }.to raise_error(Tab::Invalid, /\AChorus: /)
  end

  it "drops blank tabs when it is stored" do
    track = described_class.from_h({"tone" => "clean", "tabs" => {"Verse" => verse_tab, "Chorus" => ""}})
    expect(track.to_h).to eq({"tuning" => "standard", "tone" => "clean", "tabs" => {"Verse" => verse_tab}, "bass_tabs" => {}})
  end

  describe "bass riffs" do
    let(:bass_tab) { "G|----------------|\nD|----------------|\nA|--------2-------|\nE|0-------------3-|\n" }

    it "keeps them next to the guitar's" do
      track = described_class.from_h("bass_tabs" => {"Verse" => bass_tab, "Chorus" => " "})
      expect(track.to_h["bass_tabs"]).to eq("Verse" => bass_tab)
      expect(track.bass_tab("Verse").notes.first[1]).to eq(28)
      expect(track).not_to be_empty
    end

    it "names the section and the bass when a bass tab does not read" do
      track = described_class.from_h("bass_tabs" => {"Verse" => "G|--|\n"})
      expect { track.validate! }.to raise_error(Tab::Invalid, /Verse \(Bass\)/)
    end
  end
end
