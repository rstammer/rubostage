require "rails_helper"

RSpec.describe Song do
  it "comes from a wish by default" do
    song = build(:song)

    expect(song).to be_wish
    expect(song).not_to be_manual
  end

  it "needs the wish when it comes from one" do
    expect(build(:song, request: " ")).not_to be_valid
  end

  it "needs no wish when written by hand" do
    song = build(:song, :manual)

    expect(song).to be_valid
    expect(song).to be_manual
  end

  it "knows only the two origins" do
    expect(build(:song, origin: "radio")).not_to be_valid
  end

  it "shows the wish as its title until it has one" do
    expect(build(:song, title: nil).display_title).to eq("Starlight von Muse")
  end

  it "shows a placeholder for a hand-written song without a title" do
    expect(build(:song, :manual, title: nil).display_title).to eq("Neuer Song")
  end

  describe "its code" do
    let(:song) { create(:song, :ready, code: nil) }

    it "builds and keeps it from sheet and arrangement" do
      song.rebuild_code!
      expect(song.reload.code).to eq(song.groove.code)
      expect(song.code).to include("/stage/step")
    end

    it "plays what it keeps, so a later change to the groove leaves it alone" do
      song.update!(code: "play 60")
      expect(song.playable_code).to eq("play 60")
    end

    it "builds the code on first play when there is none yet" do
      expect(song.playable_code).to include("live_loop :conductor")
      expect(song.reload.code).to be_present
    end
  end
end
