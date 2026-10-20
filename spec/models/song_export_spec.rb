require "rails_helper"

RSpec.describe SongExport do
  around do |example|
    Dir.mktmpdir { |root| @root = Pathname(root) and example.run }
  end

  let(:song) { create(:song, :ready) }
  let(:export) { described_class.new(song, root: @root) }
  let(:dir) { @root.join("starlight") }

  it "writes into the app's exports folder unless SONGS_ROOT says otherwise" do
    expect(described_class.default_root.to_s).to eq(Rails.root.join("exports").to_s)
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
    expect(CodeCheck.problems(code)).to be_empty
  end

  it "writes NOTES.md with key, tempo, form and chords, marked as unchecked" do
    export.call
    notes = dir.join("NOTES.md").read
    expect(notes).to include(SongExport::MARK_MD, "Starlight", "Muse", "**Tonart:** B", "**Tempo:** 122 BPM")
    expect(notes).to include("| Verse | `B \\| C#m \\| G#m \\| E` |")
    expect(notes).to include("ungeprüft")
  end

  it "lists how each section is arranged once there is an arrangement" do
    song.update!(arrangement: {"sections" => {"Verse" => {"energy" => 3, "groove" => "punk", "guitar" => "power"}}})
    export.call
    expect(dir.join("NOTES.md").read).to include("| Verse | 3 | punk | power |")
  end

  it "keeps Robin's tabs in the notes" do
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

  it "refuses to overwrite a hand-written file" do
    dir.mkpath
    dir.join("live.rb").write("# by hand\nplay 60\n")
    expect { export.call }.to raise_error(SongExport::HandWritten, /live.rb/)
    expect(dir.join("live.rb").read).to eq("# by hand\nplay 60\n")
    expect(dir.join("NOTES.md")).not_to exist
  end
end
