require "rails_helper"
require Rails.root.join("../lib/osc").to_s

RSpec.describe OSC do
  it "reads back a message it built" do
    data = OSC.message("/stage/step", 7, 12)
    expect(OSC.parse(data)).to eq(["/stage/step", [7, 12]])
  end

  it "reads strings and negative numbers" do
    data = OSC.message("/x", "Verse", -3)
    expect(OSC.parse(data)).to eq(["/x", ["Verse", -3]])
  end

  it "reads floats, which Sonic Pi sends for non-integer numbers" do
    data = OSC.pad("/f") + OSC.pad(",f") + [1.5].pack("g")
    expect(OSC.parse(data)).to eq(["/f", [1.5]])
  end

  it "refuses something that is not OSC" do
    expect { OSC.parse("hello") }.to raise_error(OSC::Malformed)
  end
end
