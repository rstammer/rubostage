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

    it "lands in the songs folder whenever it is built" do
      song.rebuild_code!
      expect(Setting.songs_root.join("starlight/live.rb")).to exist
    end

    it "is built even when the folder holds a hand-written song" do
      song.update!(folder: "starlight")
      Setting.songs_root.join("starlight").mkpath
      Setting.songs_root.join("starlight/live.rb").write("play 60\n")
      expect { song.rebuild_code! }.not_to raise_error
      expect(song.reload.code).to be_present
    end
  end

  describe "its recording" do
    let(:song) { create(:song, :ready) }

    it "lasts the count-in, the form and a ring-out" do
      # 4 beats in, 16 in the form, at 122 bpm, and four seconds to ring out
      expect(song.recording_seconds).to be_within(0.01).of(20 * 60.0 / 122 + 4)
    end

    it "is named after the song" do
      expect(song.recording_filename).to eq("Starlight.wav")
    end

    it "lies outside the songs folder and git" do
      expect(song.recording_path.to_s).to start_with(Rails.root.join("storage/recordings").to_s)
    end
  end
end
