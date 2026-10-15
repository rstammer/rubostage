require "rails_helper"

RSpec.describe DrumGroove do
  it "knows the styles an arrangement may ask for" do
    expect(DrumGroove::NAMES).to include(:rock, :halftime, :shuffle, :funk, :four_floor, :punk, :ballad)
  end

  it "gives hits as [step, velocity]" do
    rock = DrumGroove.fetch(:rock)
    expect(rock[:snare]).to include([4, 1.0], [12, 1.0])
    expect(rock[:kick].map(&:first)).to include(0, 8)
  end

  it "puts the backbeat on three in halftime" do
    expect(DrumGroove.fetch(:halftime)[:snare].map(&:first)).to eq([8])
  end

  it "has ghost notes in funk, quieter than the backbeat" do
    funk = DrumGroove.fetch(:funk)
    ghosts = funk[:snare].filter_map { |step, velocity| velocity unless [4, 12].include?(step) }
    expect(ghosts).not_to be_empty
    expect(ghosts).to all(be < 0.5)
  end

  it "swings the shuffle by default" do
    expect(DrumGroove.default_swing(:shuffle)).to be > 0
    expect(DrumGroove.default_swing(:rock)).to eq(0)
  end

  it "keeps every hit inside one bar" do
    DrumGroove::NAMES.each do |name|
      DrumGroove.fetch(name).each_value do |hits|
        expect(hits.map(&:first)).to all(be_between(0, 15))
      end
    end
  end
end
