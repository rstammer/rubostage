require "rails_helper"

RSpec.describe SheetWriter do
  let(:answer) do
    {
      "title" => "Starlight", "artist" => "Muse", "key" => "B", "bpm" => 122,
      "sections" => [{"name" => "Verse", "bars" => [["B"], ["C#m"], ["G#m"], ["E"]]}],
      "form" => ["Verse"]
    }.to_json
  end

  let(:client) do
    Class.new do
      attr_reader :prompt
      def initialize(answer) = @answer = answer

      def call(prompt)
        @prompt = prompt
        @answer
      end
    end.new(answer)
  end

  it "turns a wish into a sheet" do
    sheet = described_class.new(client: client).call("Starlight von Muse")
    expect(sheet.title).to eq("Starlight")
    expect(sheet.bpm).to eq(122)
  end

  it "passes the wish on and keeps lyrics and melody out" do
    described_class.new(client: client).call("Starlight von Muse")
    expect(client.prompt).to include("Starlight von Muse")
    expect(client.prompt).to match(/no lyrics/i)
    expect(client.prompt).to match(/no melod/i)
  end
end
