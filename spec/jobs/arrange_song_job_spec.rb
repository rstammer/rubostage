require "rails_helper"

RSpec.describe ArrangeSongJob do
  let(:song) { create(:song, :ready) }
  let(:arrangement) { Arrangement.from_h({"sounds" => {"bass" => "tb303"}, "sections" => {}}, song.lead_sheet) }
  let(:writer) { instance_double(ArrangementWriter, call: arrangement) }

  before do
    allow(ArrangementWriter).to receive(:new).and_return(writer)
    allow(Player).to receive(:upgrade)
    NowPlaying.current_song_id = nil
  end

  it "stores the arrangement on the song" do
    described_class.perform_now(song)
    song.reload
    expect(song.arrangement_status).to eq("ready")
    expect(song.arrangement["sounds"]["bass"]).to eq("tb303")
  end

  it "swaps the voices of the song that is playing right now" do
    NowPlaying.current_song_id = song.id
    described_class.perform_now(song)
    expect(Player).to have_received(:upgrade).with(song.reload.voices_code)
  end

  it "leaves Sonic Pi alone when another song plays" do
    NowPlaying.current_song_id = song.id + 1
    described_class.perform_now(song)
    expect(Player).not_to have_received(:upgrade)
  end

  it "keeps the groove when no arrangement comes back" do
    allow(writer).to receive(:call).and_raise(Arrangement::Invalid, "no JSON")
    described_class.perform_now(song)
    song.reload
    expect(song.arrangement_status).to eq("failed")
    expect(song.arrangement).to be_nil
  end

  it "does not mind Sonic Pi being closed" do
    NowPlaying.current_song_id = song.id
    allow(Player).to receive(:upgrade).and_raise(Player::NotRunning)
    expect { described_class.perform_now(song) }.not_to raise_error
    expect(song.reload.arrangement_status).to eq("ready")
  end

  it "hands the wish to the writer" do
    described_class.perform_now(song, wish: "mehr Funk")
    expect(writer).to have_received(:call).with(anything, wish: "mehr Funk")
  end

  it "keeps the old arrangement when a new one fails" do
    song.update!(arrangement: arrangement.to_h, arrangement_status: "ready")
    allow(writer).to receive(:call).and_raise(ClaudeCli::Failed, "timeout")
    described_class.perform_now(song)
    song.reload
    expect(song.arrangement_status).to eq("ready")
    expect(song.arrangement["sounds"]["bass"]).to eq("tb303")
  end
end
