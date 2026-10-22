require "rails_helper"

RSpec.describe SongExport do
  around do |example|
    Dir.mktmpdir { |root| @root = Pathname(root) and example.run }
  end

  let(:song) { create(:song, :ready) }
  let(:export) { described_class.new(song, root: @root) }
  let(:dir) { @root.join("starlight") }

  it "writes into the songs folder from the settings" do
    expect(described_class.default_root).to eq(Setting.songs_root)
  end

  it "names the path after the folder it writes into" do
    exports = @root.join("exports")
    expect(described_class.new(song, root: exports).path).to eq("exports/starlight")
  end

  it "names the folder after the title, the way the songs folder does" do
    song.update!(sheet: song.sheet.merge("title" => "Chop Suey!"))
    expect(described_class.new(song, root: @root).dir).to eq(@root.join("chop_suey"))
  end

  it "writes a live.rb that plays on its own, without reporting to the stage" do
    export.call
    code = dir.join("live.rb").read
    expect(code).to start_with(SongExport::MARK)
    expect(code).to include("live_loop :conductor", "use_bpm 122")
    expect(code).not_to include("/stage/step")
    expect(code).to include("set :stage_loop, true")
    expect(CodeCheck.problems(code)).to be_empty
  end

  it "writes NOTES.md with key, tempo, form and chords, marked as unchecked" do
    export.call
    notes = dir.join("NOTES.md").read
    expect(notes).to include(SongExport::MARK_MD, "Starlight", "Muse", "**Tonart:** B", "**Tempo:** 122 BPM")
    expect(notes).to include("| Verse | `B \\| C#m \\| G#m \\| E` |")
    expect(notes).to include("ungeprüft")
  end

  it "names a two-beat bar in the notes" do
    song.update!(sheet: song.sheet.merge("beats" => 2))
    export.call
    expect(dir.join("NOTES.md").read).to include("**Takt:** 2/4")
  end

  it "keeps the bass tabs in the notes" do
    bass = "G|----------------|\nD|----------------|\nA|----------------|\nE|0---------------|\n"
    song.update!(riff_track: {"bass_tabs" => {"Verse" => bass}})
    export.call
    expect(dir.join("NOTES.md").read).to include("### Verse (Bass)", "E|0---------------|")
    expect(dir.join("live.rb").read).to include("live_loop :bass_riff")
  end

  it "writes a held bar as % in the notes" do
    song.update!(sheet: song.sheet.merge("sections" => [{"name" => "Verse", "bars" => [["B"], [], ["E"]]}]))
    export.call
    expect(dir.join("NOTES.md").read).to include("| Verse | `B \\| % \\| E` |")
  end

  it "lists how each section is arranged once there is an arrangement" do
    song.update!(arrangement: {"sections" => {"Verse" => {"energy" => 3, "groove" => "punk", "guitar" => "power"}}})
    export.call
    expect(dir.join("NOTES.md").read).to include("| Verse | 3 | punk | power |")
  end

  it "keeps the tabs in the notes" do
    tab = "e|----------------|\nB|----------------|\nG|----------------|\nD|----------------|\nA|----------------|\nE|0---------------|\n"
    song.update!(riff_track: {"tuning" => "drop_d", "tone" => "clean", "tabs" => {"Verse" => tab}})
    export.call
    notes = dir.join("NOTES.md").read
    expect(notes).to include("drop_d", "E|0---------------|")
    expect(dir.join("live.rb").read).to include("live_loop :riff")
  end

  it "leaves other files in the folder alone" do
    dir.mkpath
    dir.join("lyrics.md").write("mine")
    export.call
    expect(dir.join("lyrics.md").read).to eq("mine")
  end

  it "overwrites what an earlier export wrote" do
    export.call
    song.update!(bpm: 100, sheet: song.sheet.merge("bpm" => 100))
    described_class.new(song.reload, root: @root).call
    expect(dir.join("live.rb").read).to include("use_bpm 100")
  end

  it "refuses to overwrite a hand-written file in its own folder" do
    song.update!(folder: "starlight")
    dir.mkpath
    dir.join("live.rb").write("# by hand\nplay 60\n")
    expect { export.call }.to raise_error(SongExport::HandWritten, /live.rb/)
    expect(dir.join("live.rb").read).to eq("# by hand\nplay 60\n")
    expect(dir.join("NOTES.md")).not_to exist
  end

  describe "the song's folder" do
    it "is named after the title on first export and kept" do
      export.call
      expect(song.reload.folder).to eq("starlight")
    end

    it "stays when the title changes, so the history in the repo holds" do
      export.call
      song.update!(title: "Starlight (live)", sheet: song.sheet.merge("title" => "Starlight (live)"))
      expect(described_class.new(song.reload, root: @root).dir).to eq(dir)
    end

    it "gets a number when another song has the name already" do
      export.call
      other = create(:song, :ready)
      expect(described_class.new(other, root: @root).call.dir).to eq(@root.join("starlight_2"))
    end

    it "steps around a folder written by hand" do
      dir.mkpath
      dir.join("live.rb").write("play 60\n")
      expect(export.call.dir).to eq(@root.join("starlight_2"))
    end

    it "takes over an exported folder no song owns" do
      dir.mkpath
      dir.join("live.rb").write("#{SongExport::MARK}\nplay 60\n")
      expect(export.call.dir).to eq(dir)
    end
  end

  describe "a song written by hand" do
    let(:song) do
      create(:song, :ready, :manual, artist: "").tap { |s| s.update!(sheet: s.sheet.merge("artist" => "")) }
    end

    it "is not called a cover or unchecked" do
      export.call
      notes = dir.join("NOTES.md").read
      expect(notes).to include("Eigener Song")
      expect(notes).not_to include("Cover", "ungeprüft")
    end
  end

  describe "removing" do
    it "takes the exported files away, and the folder once it is empty" do
      export.call
      export.remove
      expect(dir).not_to exist
    end

    it "leaves files written by hand where they are" do
      export.call
      dir.join("lyrics.md").write("mine")
      export.remove
      expect(dir.children.map { |f| f.basename.to_s }).to eq(["lyrics.md"])
    end

    it "does not mind a song that was never exported" do
      expect { export.remove }.not_to raise_error
    end
  end

  describe "every song at once" do
    it "writes each ready song and steps over hand-written ones" do
      create(:song, :ready, folder: "starlight")
      @root.join("starlight").mkpath
      @root.join("starlight/live.rb").write("play 60\n")
      other = create(:song, :ready).tap { |s| s.update!(title: "Bliss", sheet: s.sheet.merge("title" => "Bliss")) }
      create(:song)
      described_class.mirror_all(root: @root)
      expect(@root.join("bliss/live.rb")).to exist
      expect(@root.join("starlight/live.rb").read).to eq("play 60\n")
      expect(other.reload.folder).to eq("bliss")
    end
  end
end
