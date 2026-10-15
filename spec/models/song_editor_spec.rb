require "rails_helper"

RSpec.describe SongEditor do
  let(:song) { create(:song, :ready) }
  let(:tab) do
    <<~TAB
      e|----------------|
      B|----------------|
      G|----------------|
      D|----------------|
      A|----------------|
      E|7---7---9---9---|
    TAB
  end

  def params(**changes)
    rows = changes.delete(:sections) || {"0" => {"original" => "Verse", "name" => "Verse", "chords" => "B | C#m | G#m | E"}}
    {"title" => "Starlight", "artist" => "Muse", "key" => "B", "bpm" => "122", "form" => "Verse",
     "tuning" => "standard", "tone" => "crunch", "sections" => rows}.merge(changes.transform_keys(&:to_s))
  end

  describe "filled from a song" do
    it "writes the chords bar by bar, split bars with a space" do
      song.update!(sheet: song.sheet.merge("sections" => [{"name" => "Verse", "bars" => [["B"], ["F#", "F#/A#"]]}]))
      editor = described_class.for(song)
      expect(editor.rows.first(1).map { |row| [row.name, row.chords] }).to eq([["Verse", "B | F# F#/A#"]])
      expect([editor.bpm, editor.form]).to eq([122, "Verse"])
    end

    it "shows the arrangement and the tabs of each section" do
      song.update!(
        arrangement: {"sections" => {"Verse" => {"groove" => "funk", "guitar" => "stabs", "energy" => 1}}},
        riff_track: {"tuning" => "drop_d", "tabs" => {"Verse" => tab}}
      )
      editor = described_class.for(song)
      row = editor.rows.first
      expect([row.groove, row.guitar, row.energy, row.tab]).to eq(["funk", "stabs", 1, tab])
      expect([editor.tuning, editor.arranged?]).to eq(["drop_d", true])
    end

    it "offers one empty row for a new section" do
      expect(described_class.for(song).rows.last.name).to be_blank
    end
  end

  describe "saving" do
    it "stores the edited sheet and the song's own columns" do
      editor = described_class.new(song, params(title: "Starlight (live)", bpm: "118", key: "C#"))
      expect(editor.save).to be(true)
      song.reload
      expect([song.title, song.bpm, song.key]).to eq(["Starlight (live)", 118, "C#"])
      expect(song.lead_sheet.bpm).to eq(118)
    end

    it "reads chords as bars between bar lines and line breaks" do
      rows = {"0" => {"original" => "Verse", "name" => "Verse", "chords" => "B | C#m\nG#m E | E"}}
      described_class.new(song, params(sections: rows)).save
      expect(song.reload.sheet["sections"].first["bars"]).to eq([["B"], ["C#m"], ["G#m", "E"], ["E"]])
    end

    it "adds a section from the empty row and takes the form as a list" do
      rows = {
        "0" => {"original" => "Verse", "name" => "Verse", "chords" => "B | E"},
        "1" => {"original" => "", "name" => "Chorus", "chords" => "G#m | E"}
      }
      described_class.new(song, params(sections: rows, form: "Verse, Chorus, Verse")).save
      expect(song.reload.lead_sheet.form).to eq(%w[Verse Chorus Verse])
    end

    it "drops a section whose name and chords were cleared" do
      rows = {
        "0" => {"original" => "Verse", "name" => "Verse", "chords" => "B | E"},
        "1" => {"original" => "Bridge", "name" => "", "chords" => ""}
      }
      expect(described_class.new(song, params(sections: rows)).save).to be(true)
      expect(song.reload.lead_sheet.sections.map(&:name)).to eq(["Verse"])
    end

    it "keeps the arrangement's patterns and takes the edited style" do
      song.update!(arrangement: {"sounds" => {"bass" => "tb303"}, "sections" => {"Verse" => {"bass" => "1..51..51..51..5"}}})
      rows = {"0" => {"original" => "Verse", "name" => "Verse", "chords" => "B | E",
                      "energy" => "3", "groove" => "punk", "guitar" => "palm", "swing" => "0", "fill" => "1"}}
      described_class.new(song, params(sections: rows)).save
      part = song.reload.full_arrangement.section("Verse")
      expect([part.groove, part.guitar, part.energy, part.fill]).to eq([:punk, :palm, 3, true])
      expect(part.bass.map(&:first)).to eq([0, 3, 4, 7, 8, 11, 12, 15])
      expect(song.full_arrangement.sounds[:bass]).to eq(:tb303)
    end

    it "carries arrangement and tab along when a section is renamed" do
      song.update!(arrangement: {"sections" => {"Verse" => {"groove" => "funk"}}})
      rows = {"0" => {"original" => "Verse", "name" => "Strophe", "chords" => "B | E", "groove" => "funk", "tab" => tab}}
      described_class.new(song, params(sections: rows, form: "Strophe")).save
      song.reload
      expect(song.full_arrangement.section("Strophe").groove).to eq(:funk)
      expect(song.riffs.tab("Strophe").notes.first).to eq([0, 47, 4])
    end

    it "leaves songs without an arrangement without one" do
      described_class.new(song, params).save
      expect(song.reload.arrangement).to be_nil
    end

    it "stores the tabs with their tuning and tone" do
      rows = {"0" => {"original" => "Verse", "name" => "Verse", "chords" => "B | E", "tab" => tab}}
      described_class.new(song, params(sections: rows, tuning: "half_down", tone: "clean")).save
      expect(song.reload.riff_track).to eq({"tuning" => "half_down", "tone" => "clean", "tabs" => {"Verse" => tab}})
    end

    describe "refuses and keeps what was typed" do
      it "a chord it cannot read" do
        rows = {"0" => {"original" => "Verse", "name" => "Verse", "chords" => "B | Hm"}}
        editor = described_class.new(song, params(sections: rows))
        expect(editor.save).to be(false)
        expect(editor.error).to be_present
        expect(editor.rows.first.chords).to eq("B | Hm")
        expect(song.reload.sheet["sections"].first["bars"].size).to eq(4)
      end

      it "a form naming a section that does not exist" do
        editor = described_class.new(song, params(form: "Verse, Chorus"))
        expect(editor.save).to be(false)
        expect(editor.error).to include("Chorus")
      end

      it "a tempo that is not a number" do
        expect(described_class.new(song, params(bpm: "schnell")).save).to be(false)
      end

      it "a tab that does not read, naming the section" do
        rows = {"0" => {"original" => "Verse", "name" => "Verse", "chords" => "B | E", "tab" => "e|---|"}}
        editor = described_class.new(song, params(sections: rows))
        expect(editor.save).to be(false)
        expect(editor.error).to start_with("Verse: ")
        expect(editor.rows.first.tab).to eq("e|---|")
      end
    end

    describe "while the song plays" do
      it "can swap the voices in when tempo and the length of every part stay" do
        rows = {"0" => {"original" => "Verse", "name" => "Verse", "chords" => "E | E | E | E", "tab" => tab}}
        editor = described_class.new(song, params(sections: rows))
        editor.save
        expect(editor).to be_swappable
      end

      it "needs a restart when the tempo or the length of a part changes" do
        expect(described_class.new(song, params(bpm: "100")).tap(&:save)).not_to be_swappable
        rows = {"0" => {"original" => "Verse", "name" => "Verse", "chords" => "B | E"}}
        expect(described_class.new(create(:song, :ready), params(sections: rows)).tap(&:save)).not_to be_swappable
      end
    end
  end
end
