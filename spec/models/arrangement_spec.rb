require "rails_helper"

RSpec.describe Arrangement do
  let(:sheet) do
    SongSheet.from_h(
      "title" => "Starlight", "artist" => "Muse", "key" => "B", "bpm" => 122,
      "sections" => [
        {"name" => "Verse", "bars" => [["B"], ["C#m"]]},
        {"name" => "Chorus", "bars" => [["G#m"], ["E"]]}
      ],
      "form" => ["Verse", "Chorus"]
    )
  end

  let(:data) do
    {
      "sounds" => {"bass" => "tb303", "comp" => "pulse", "pad" => "dark_ambience", "distorted" => true},
      "sections" => {
        "Verse" => {
          "energy" => 1,
          "kick" => "x.......x.x.....", "snare" => "....x.......x...",
          "hat" => "x.x.x.x.x.x.x.x.", "open_hat" => "..............x.",
          "bass" => "1..1..5.1..1..8.", "comp" => "x..x..x.........", "pad" => true
        },
        "Chorus" => {
          "energy" => 3,
          "kick" => "x...x...x...x...", "snare" => "....x.......x...",
          "hat" => "xxxxxxxxxxxxxxxx", "open_hat" => "................",
          "bass" => "1.1.1.1.1.1.1.1.", "comp" => "x.x.x.x.x.x.x.x.", "pad" => false
        }
      }
    }
  end

  def arrangement(overrides = {}) = described_class.from_h(data.deep_merge(overrides), sheet)

  it "reads sounds and section patterns" do
    a = arrangement
    expect(a.sounds).to eq(bass: :tb303, comp: :pulse, pad: :dark_ambience, distorted: true)
    expect(a.section("Verse").kick).to eq([0, 8, 10])
    expect(a.section("Chorus").energy).to eq(3)
  end

  it "reads bass patterns as intervals over the root" do
    expect(arrangement.section("Verse").bass).to eq([[0, 0], [3, 0], [6, 7], [8, 0], [11, 0], [14, 12]])
  end

  it "falls back to a plain pattern for a section it was not told about" do
    a = arrangement("sections" => {"Chorus" => nil})
    expect(a.section("Chorus").snare).to eq([4, 12])
  end

  it "falls back to safe sounds for ones it does not know" do
    a = arrangement("sounds" => {"bass" => "kazoo", "comp" => "laser"})
    expect(a.sounds).to include(bass: :fm, comp: :pluck)
  end

  it "refuses a pattern that is not sixteen steps" do
    expect { arrangement("sections" => {"Verse" => {"kick" => "x.x"}}) }.to raise_error(Arrangement::Invalid, /kick/)
  end

  it "refuses characters a pattern cannot have" do
    expect { arrangement("sections" => {"Verse" => {"bass" => "1..9............"}}) }.to raise_error(Arrangement::Invalid, /bass/)
  end

  it "keeps energy between 1 and 3" do
    expect(arrangement("sections" => {"Verse" => {"energy" => 9}}).section("Verse").energy).to eq(3)
  end

  it "pulls the JSON out of a chatty answer" do
    a = described_class.parse("Sure!\n```json\n#{data.to_json}\n```", sheet)
    expect(a.sounds[:bass]).to eq(:tb303)
  end

  it "round-trips through a hash" do
    a = arrangement
    expect(described_class.from_h(a.to_h, sheet).to_h).to eq(a.to_h)
  end

  describe "groove and playing style" do
    it "reads a groove style, swing, fill and how the guitar plays" do
      part = arrangement("sections" => {"Verse" => {"groove" => "halftime", "swing" => 0.2, "fill" => true, "guitar" => "palm"}}).section("Verse")
      expect(part.groove).to eq(:halftime)
      expect(part.swing).to eq(0.2)
      expect(part.fill).to be(true)
      expect(part.guitar).to eq(:palm)
    end

    it "plays the drum patterns it was given when no style is named" do
      expect(arrangement.section("Verse").groove).to eq(:custom)
    end

    it "plays rock when it knows neither style nor patterns" do
      a = described_class.from_h({"sections" => {}}, sheet)
      expect(a.section("Verse").groove).to eq(:rock)
    end

    it "falls back for a style or guitar it does not know" do
      part = arrangement("sections" => {"Verse" => {"groove" => "polka", "guitar" => "banjo"}}).section("Verse")
      expect(part.groove).to eq(:custom)
      expect(part.guitar).to eq(:power)
    end

    it "takes the style's swing when none is given and keeps it musical" do
      expect(arrangement("sections" => {"Verse" => {"groove" => "shuffle"}}).section("Verse").swing).to eq(DrumGroove.default_swing(:shuffle))
      expect(arrangement("sections" => {"Verse" => {"swing" => 5}}).section("Verse").swing).to eq(0.33)
    end

    it "strums instead of power chords when the guitar is not distorted" do
      a = arrangement("sounds" => {"distorted" => false}, "sections" => {"Verse" => {"guitar" => nil}})
      expect(a.section("Verse").guitar).to eq(:strum)
    end
  end
end
