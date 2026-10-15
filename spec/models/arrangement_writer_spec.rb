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

  it "asks for original parts, not a transcription of the record" do
    described_class.new(client: client).call(sheet)
    expect(client.prompt).to match(/own patterns/i)
    expect(client.prompt).to match(/not a transcription/i)
  end
end
