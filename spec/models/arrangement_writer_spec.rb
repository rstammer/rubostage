require "rails_helper"

RSpec.describe ArrangementWriter do
  let(:sheet) do
    SongSheet.from_h(
      "title" => "Starlight", "artist" => "Muse", "key" => "B", "bpm" => 122,
      "sections" => [{"name" => "Verse", "bars" => [["B"], ["C#m"]]}],
      "form" => ["Verse"]
    )
  end

  let(:client) do
    Class.new do
      attr_reader :prompt

      def call(prompt)
        @prompt = prompt
        {"sounds" => {"bass" => "tb303"}, "sections" => {}}.to_json
      end
    end.new
  end

  it "asks for an arrangement of the sheet and reads it" do
    arrangement = described_class.new(client: client).call(sheet)
    expect(arrangement.sounds[:bass]).to eq(:tb303)
    expect(client.prompt).to include("Starlight", "Muse", "122", "Verse", "B | C#m")
  end

  it "offers the groove styles and guitar parts it can play" do
    described_class.new(client: client).call(sheet)
    expect(client.prompt).to include("halftime", "shuffle", "four_floor", "palm", "power")
  end

  it "asks for original parts, not a transcription of the record" do
    described_class.new(client: client).call(sheet)
    expect(client.prompt).to match(/own patterns/i)
    expect(client.prompt).to match(/not a transcription/i)
  end

  it "passes on what Robin wishes for the arrangement" do
    described_class.new(client: client).call(sheet, wish: "ruhiger, Reggae im Refrain")
    expect(client.prompt).to include("ruhiger, Reggae im Refrain")
  end

  it "asks for no wish when there is none" do
    described_class.new(client: client).call(sheet, wish: " ")
    expect(client.prompt).not_to match(/wish/i)
  end

  it "names no band for a song of Robin's own" do
    own = SongSheet.from_h(sheet.to_h.merge("title" => "Rahmersee", "artist" => ""))
    described_class.new(client: client).call(own)
    expect(client.prompt).to include("Rahmersee, the busker's own song")
    expect(client.prompt).not_to include(" by ,")
  end
end
