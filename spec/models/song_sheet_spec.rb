require "rails_helper"

RSpec.describe SongSheet do
  let(:data) do
    {
      "title" => "Starlight",
      "artist" => "Muse",
      "key" => "B",
      "bpm" => 122,
      "sections" => [
        {"name" => "Verse", "bars" => [["B"], ["C#m"], ["G#m"], ["E"]]},
        {"name" => "Bridge", "bars" => [["G#m"], ["E"], ["B"], ["F#", "F#/A#"]]}
      ],
      "form" => ["Verse", "Verse", "Bridge", "Verse"]
    }
  end

  it "reads a sheet" do
    sheet = described_class.from_h(data)
    expect(sheet.title).to eq("Starlight")
    expect(sheet.bpm).to eq(122)
    expect(sheet.sections.map(&:name)).to eq(["Verse", "Bridge"])
    expect(sheet.form).to eq(["Verse", "Verse", "Bridge", "Verse"])
  end

  it "plays the form in order" do
    sheet = described_class.from_h(data)
    expect(sheet.played_sections.map(&:name)).to eq(["Verse", "Verse", "Bridge", "Verse"])
  end

  it "plays every section once when there is no form" do
    sheet = described_class.from_h(data.except("form"))
    expect(sheet.form).to eq(["Verse", "Bridge"])
  end

  it "pulls the JSON out of a chatty answer" do
    text = "Here you go:\n```json\n#{data.to_json}\n```\nEnjoy!"
    expect(described_class.parse(text).title).to eq("Starlight")
  end

  it "refuses an answer without JSON" do
    expect { described_class.parse("no idea") }.to raise_error(SongSheet::Invalid)
  end

  it "refuses a tempo out of range" do
    expect { described_class.from_h(data.merge("bpm" => 400)) }.to raise_error(SongSheet::Invalid, /bpm/)
  end

  it "refuses a form that names a missing section" do
    expect { described_class.from_h(data.merge("form" => ["Chorus"])) }.to raise_error(SongSheet::Invalid, /Chorus/)
  end

  it "refuses a chord it cannot read" do
    bad = data.deep_dup
    bad["sections"][0]["bars"][0] = ["Quatsch"]
    expect { described_class.from_h(bad) }.to raise_error(SongSheet::Invalid)
  end

  it "refuses more than two chords in a bar" do
    bad = data.deep_dup
    bad["sections"][0]["bars"][0] = ["B", "E", "F#"]
    expect { described_class.from_h(bad) }.to raise_error(SongSheet::Invalid, /bar/)
  end

  it "round-trips through a hash" do
    sheet = described_class.from_h(data)
    expect(described_class.from_h(sheet.to_h).to_h).to eq(sheet.to_h)
  end
end
