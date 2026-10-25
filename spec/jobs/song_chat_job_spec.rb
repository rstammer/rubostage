require "rails_helper"

RSpec.describe SongChatJob do
  let(:song) { create(:song, :ready) }
  let(:chat) { instance_double(SongChat, call: "Mach den Verse leiser.") }

  before do
    song.messages.create!(role: "user", body: "Was meinst du?")
    allow(SongChat).to receive(:new).with(song).and_return(chat)
  end

  it "shows the answer as it comes in, then keeps it" do
    allow(chat).to receive(:call).and_yield("Mach den ").and_yield("Verse leiser.").and_return("Mach den Verse leiser.")
    draft = instance_double(ChatDraft, write: nil, remove: nil, working: nil)
    allow(ChatDraft).to receive(:new).and_return(draft)
    described_class.perform_now(song)
    expect(draft).to have_received(:write).with("Mach den ").ordered
    expect(draft).to have_received(:write).with("Verse leiser.").ordered
    expect(draft).to have_received(:remove)
    expect(song.messages.last.body).to eq("Mach den Verse leiser.")
  end

  it "adds Claude's answer to the conversation" do
    described_class.perform_now(song)
    expect(song.messages.last).to have_attributes(role: "assistant", body: "Mach den Verse leiser.")
  end

  it "says so in the conversation when Claude does not answer" do
    allow(chat).to receive(:call).and_raise(ClaudeCli::Failed, "offline")
    described_class.perform_now(song)
    expect(song.messages.last).to have_attributes(role: "assistant")
    expect(song.messages.last.body).to include("keine Antwort")
  end
end
