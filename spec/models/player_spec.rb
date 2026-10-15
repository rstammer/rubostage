require "rails_helper"

RSpec.describe Player do
  let(:server) { instance_double(SonicPi, run: nil, stop: nil) }

  before { allow(SonicPi).to receive(:running).and_return(server) }

  it "stops what is playing before it starts a song, so the form begins at the top" do
    Player.play("play 60")
    expect(server).to have_received(:stop).ordered
    expect(server).to have_received(:run).with("play 60").ordered
  end

  it "queues a command for the conductor" do
    Player.command(:repeat)
    expect(server).to have_received(:run).with(/\Aset :stage_cmd, \[\d+, :repeat, nil\]\z/)
  end

  it "queues a jump with its form position" do
    Player.command(:jump, 3)
    expect(server).to have_received(:run).with(/\Aset :stage_cmd, \[\d+, :jump, 3\]\z/)
  end

  it "refuses commands it does not know" do
    expect { Player.command(:explode) }.to raise_error(ArgumentError)
  end

  it "says so when Sonic Pi is not running" do
    allow(SonicPi).to receive(:running).and_return(nil)
    expect { Player.command(:next) }.to raise_error(Player::NotRunning)
  end
end
