require "rails_helper"

RSpec.describe ChordSymbol do
  def parse(text) = described_class.parse(text)

  it "reads a major triad" do
    expect(parse("B").pitch_classes).to eq([11, 3, 6])
  end

  it "reads sharps and flats" do
    expect(parse("C#m").root).to eq(1)
    expect(parse("Bb").root).to eq(10)
  end

  it "reads the usual qualities" do
    expect(parse("Am").intervals).to eq([0, 3, 7])
    expect(parse("G7").intervals).to eq([0, 4, 7, 10])
    expect(parse("Cmaj7").intervals).to eq([0, 4, 7, 11])
    expect(parse("Em7").intervals).to eq([0, 3, 7, 10])
    expect(parse("Dsus4").intervals).to eq([0, 5, 7])
    expect(parse("E5").intervals).to eq([0, 7])
  end

  it "keeps a slash bass apart from the root" do
    chord = parse("A/C#")
    expect(chord.root).to eq(9)
    expect(chord.bass).to eq(1)
  end

  it "uses the root as bass without a slash" do
    expect(parse("F#").bass).to eq(6)
  end

  it "falls back to the triad on a quality it does not know" do
    expect(parse("Cm(add11)").intervals).to eq([0, 3, 7])
  end

  it "refuses something that is not a chord" do
    expect { parse("Hallo") }.to raise_error(ChordSymbol::Invalid)
  end

  it "gives a bass note in the low register" do
    expect(parse("E").bass_note).to eq(40)
    expect(parse("C").bass_note).to eq(36)
  end

  it "voices the chord around middle C" do
    voicing = parse("G#m").voicing
    expect(voicing.map { |n| n % 12 }.sort).to eq([3, 8, 11])
    expect(voicing).to all(be_between(57, 72))
  end
end
