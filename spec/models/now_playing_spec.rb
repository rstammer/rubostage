require "rails_helper"

RSpec.describe NowPlaying do
  let(:song) do
    create(:song, :ready, sheet: {
      "title" => "Starlight", "artist" => "Muse", "key" => "B", "bpm" => 122,
      "sections" => [
        {"name" => "Verse", "bars" => [["B"], ["C#m"]]},
        {"name" => "Bridge", "bars" => [["G#m", "E"]]}
      ],
      "form" => ["Verse", "Bridge"]
    })
  end

  it "names the chord, the next one and the section" do
    now = described_class.new(song, 1)
    expect(now.chord).to eq("C#m")
    expect(now.next_chord).to eq("G#m")
    expect(now.section).to eq("Verse")
  end

  it "knows which position of the form is playing" do
    expect(described_class.new(song, 1).form_position).to eq(0)
    expect(described_class.new(song, 2).form_position).to eq(1)
  end

  it "says the ending comes after the last chord" do
    now = described_class.new(song, 3)
    expect(now.chord).to eq("E")
    expect(now.next_chord).to eq("Schluss")
  end

  it "knows when the song has ended" do
    now = described_class.new(song, -1)
    expect(now).to be_finished
    expect(now.chord).to be_nil
  end

  it "renders a panel that marks the chord and the form position" do
    html = ApplicationController.render(partial: "songs/now", locals: {now: described_class.new(song, 2)})
    expect(html).to include("G#m", "dann", "E", "Bridge", "#chord-1-0", "#form-1")
  end

  it "renders the ending" do
    html = ApplicationController.render(partial: "songs/now", locals: {now: described_class.new(song, -1)})
    expect(html).to include("Schluss")
  end

  it "clears what was queued when a new section starts" do
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    allow(Turbo::StreamsChannel).to receive(:broadcast_update_to)
    described_class.broadcast(song, 2)
    expect(Turbo::StreamsChannel).to have_received(:broadcast_update_to).with(song, :now, target: "queued", html: "")
  end

  it "leaves the queue alone in the middle of a section" do
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    allow(Turbo::StreamsChannel).to receive(:broadcast_update_to)
    described_class.broadcast(song, 1)
    expect(Turbo::StreamsChannel).not_to have_received(:broadcast_update_to)
  end
end
