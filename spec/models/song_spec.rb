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

  it "needs no wish when Robin writes it himself" do
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

  it "shows a placeholder for a song of his own without a title" do
    expect(build(:song, :manual, title: nil).display_title).to eq("Neuer Song")
  end
end
