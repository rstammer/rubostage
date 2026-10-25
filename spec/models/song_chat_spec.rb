require "rails_helper"

RSpec.describe SongChat do
  let(:song) { create(:song, :ready, lyrics: "Far away, this ship is taking me far away") }

  let(:client) do
    Class.new do
      attr_reader :prompt, :toolbox

      def call(prompt, toolbox: nil)
        @prompt = prompt
        @toolbox = toolbox
        "Probier im Chorus mal halftime."
      end
    end.new
  end

  before do
    song.messages.create!(role: "user", body: "Wie kriege ich mehr Druck in den Verse?")
  end

  it "answers the last question with what Claude says" do
    expect(described_class.new(song, client: client).call).to eq("Probier im Chorus mal halftime.")
  end

  it "tells Claude the song: key, tempo, bar, chords and form" do
    described_class.new(song, client: client).call
    expect(client.prompt).to include("Starlight", "Muse", "122", "key B", "4/4", "Verse: B | C#m | G#m | E", "Form: Verse")
  end

  it "passes on the arrangement and the riffs" do
    song.update!(arrangement: {"sounds" => {"bass" => "tb303"}, "sections" => {"Verse" => {"energy" => 3, "groove" => "punk"}}},
      riff_track: {"tabs" => {"Verse" => "e|0---|"}})
    described_class.new(song, client: client).call
    expect(client.prompt).to include("tb303", "punk", "e|0---|")
  end

  it "keeps the lyrics to itself" do
    described_class.new(song, client: client).call
    expect(client.prompt).not_to include("this ship")
  end

  it "brings along the conversation so far, oldest first" do
    song.messages.create!(role: "assistant", body: "Mehr Energie und Palm Mutes.")
    song.messages.create!(role: "user", body: "Und im Chorus?")
    described_class.new(song, client: client).call
    prompt = client.prompt
    expect(prompt.index("Wie kriege ich")).to be < prompt.index("Mehr Energie")
    expect(prompt.index("Mehr Energie")).to be < prompt.index("Und im Chorus?")
  end

  it "lets Claude change the song with the song tools, undoable" do
    described_class.new(song, client: client).call
    expect(client.toolbox.song).to eq(song)
    expect(client.toolbox.tools).to eq(SongTools.all)
    expect(client.prompt).to match(/undo/i)
    expect(client.prompt).to include("edit_riffs", "rearrange", "play")
  end
end
