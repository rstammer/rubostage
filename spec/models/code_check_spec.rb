require "rails_helper"

RSpec.describe CodeCheck do
  it "passes valid Sonic Pi code" do
    expect(described_class.problems("use_bpm 120\nplay 60")).to be_empty
  end

  it "reports a syntax error" do
    expect(described_class.problems("live_loop :x do\n  play 60\n")).to include(/syntax/i)
  end

  it "reports a built-in fn name used as a variable" do
    expect(described_class.problems("ring = [1, 2]")).to include(/ring/)
    expect(described_class.problems("chord = 1")).to include(/chord/)
  end

  it "does not mind the fn being called" do
    expect(described_class.problems("play chord(:e3, :minor)")).to be_empty
  end
end
