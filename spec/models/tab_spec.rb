require "rails_helper"

RSpec.describe Tab do
  let(:riff) do
    <<~TAB
      e|----------------|
      B|----------------|
      G|----------------|
      D|----------------|
      A|--------3-------|
      E|0---0-------12--|
    TAB
  end

  it "turns each fret into a note at its sixteenth" do
    tab = described_class.parse(riff)
    expect(tab.steps).to eq(16)
    expect(tab.notes.map { |step, pitch, _held| [step, pitch] }).to eq([[0, 40], [4, 40], [8, 48], [12, 52]])
  end

  it "holds a note until the string plays again or the tab ends" do
    held = described_class.parse(riff).notes.map(&:last)
    expect(held).to eq([4, 8, 8, 4])
  end

  it "reads the top line as the high string" do
    tab = described_class.parse(riff.sub("e|----------------|", "e|0---------------|"))
    expect(tab.notes).to include([0, 64, 16])
  end

  it "plays a chord when several strings hit together" do
    tab = described_class.parse(<<~TAB)
      e|----------------|
      B|----------------|
      G|----------------|
      D|4---------------|
      A|4---------------|
      E|2---------------|
    TAB
    expect(tab.notes.map { |step, pitch, _| [step, pitch] }).to contain_exactly([0, 42], [0, 49], [0, 54])
  end

  it "joins bars and systems into one riff" do
    two_bars = riff.lines.map { |line| line.chomp + "----------------|\n" }.join
    tab = described_class.parse(two_bars + "\n" + riff)
    expect(tab.steps).to eq(48)
    expect(tab.notes.last.first).to eq(32 + 12)
  end

  it "plays a muted x as a short dead note" do
    tab = described_class.parse(riff.sub("E|0---0", "E|0-x-0"))
    expect(tab.notes).to include([2, 40, 0])
  end

  it "ignores bends, slides and hammer-ons, playing the frets they lead to" do
    tab = described_class.parse(riff.sub("E|0---0---", "E|0h2-0/5-"))
    expect(tab.notes.map(&:first).first(4)).to eq([0, 2, 4, 6])
  end

  it "follows the tuning" do
    tab = described_class.parse(riff, tuning: "drop_d")
    expect(tab.notes.first[1]).to eq(38)
  end

  it "takes string names with or without a bar line, or none at all" do
    bare = riff.lines.map { |line| line.sub(/\A\w\|/, "") }.join
    expect(described_class.parse(bare).notes).to eq(described_class.parse(riff).notes)
  end

  it "is empty for blank text" do
    expect(described_class.parse(" \n")).to be_nil
  end

  it "names the strings of a tuning, high string first and in lower case" do
    expect(Tab.labels("standard")).to eq(%w[e B G D A E])
    expect(Tab.labels("drop_d").last).to eq("D")
    expect(Tab.labels("half_down")).to eq(%w[eb Bb Gb Db Ab Eb])
  end

  describe "refuses" do
    it "a tab without six lines per system" do
      expect { described_class.parse(riff.lines.first(5).join) }.to raise_error(Tab::Invalid, /six lines/)
    end

    it "a bar that is not sixteen steps long" do
      expect { described_class.parse(riff.sub("A|--------3-------|", "A|--------3------|")) }
        .to raise_error(Tab::Invalid, /A string, bar 1: 15 steps/)
    end

    it "signs it cannot read" do
      expect { described_class.parse(riff.sub("E|0---", "E|0-?-")) }.to raise_error(Tab::Invalid, /"\?"/)
    end

    it "an unknown tuning" do
      expect { described_class.parse(riff, tuning: "open_g") }.to raise_error(Tab::Invalid, /tuning/)
    end
  end

  describe "for the bass" do
    let(:bass_tab) { "G|----------------|\nD|----------------|\nA|--------2-------|\nE|0-------------3-|\n" }

    it "reads four strings, an octave below the guitar's lowest four" do
      tab = described_class.parse(bass_tab, bass: true)
      expect(tab.notes.map { |step, pitch, _held| [step, pitch] }).to eq([[0, 28], [8, 35], [14, 31]])
    end

    it "follows the tuning of the song" do
      tab = described_class.parse(bass_tab, tuning: "drop_d", bass: true)
      expect(tab.notes.first[1]).to eq(26)
    end

    it "wants four lines per block" do
      expect { described_class.parse(bass_tab.lines.first(3).join, bass: true) }.to raise_error(Tab::Invalid, /four/)
    end

    it "names its strings from the top" do
      expect(described_class.labels("standard", bass: true)).to eq(%w[G D A E])
    end
  end
end
