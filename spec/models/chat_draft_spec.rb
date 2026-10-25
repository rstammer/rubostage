require "rails_helper"

RSpec.describe ChatDraft do
  let(:song) { create(:song, :ready) }
  let(:clock) { [0.0] }
  let(:draft) { described_class.new(song, key: "abc", every: 0.2, clock: -> { clock.first }) }

  before do
    %i[broadcast_append_to broadcast_replace_to broadcast_remove_to].each { |action| allow(Turbo::StreamsChannel).to receive(action) }
  end

  it "puts the answer so far into the chat" do
    draft.write("Der **Bass**")
    expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
      .with(song, :chat, target: "chat_messages", partial: "song_messages/draft", locals: {id: "draft_abc", text: "Der **Bass**", doing: nil})
  end

  it "sets it in markdown" do
    html = ApplicationController.render(partial: "song_messages/draft", locals: {id: "draft_abc", text: "Der **Bass**", doing: "liest den Song"})
    expect(html).to include('id="draft_abc"', "<strong>Bass</strong>", "liest den Song")
  end

  it "updates it at most every so often" do
    draft.write("a")
    draft.write("b")
    expect(Turbo::StreamsChannel).not_to have_received(:broadcast_replace_to)
    clock[0] = 0.3
    draft.write("c")
    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to)
      .with(song, :chat, target: "draft_abc", partial: "song_messages/draft", locals: {id: "draft_abc", text: "abc", doing: nil})
  end

  it "says what Claude is doing while it uses a tool" do
    draft.working("edit_band")
    expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to)
      .with(song, :chat, target: "chat_messages", partial: "song_messages/draft", locals: {id: "draft_abc", text: "", doing: "ändert die Band"})
  end

  it "goes away when the answer is in" do
    draft.write("a")
    draft.remove
    expect(Turbo::StreamsChannel).to have_received(:broadcast_remove_to).with(song, :chat, target: "draft_abc")
  end
end
