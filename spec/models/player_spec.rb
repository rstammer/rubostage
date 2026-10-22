require "rails_helper"

RSpec.describe Player do
  let(:server) { instance_double(SonicPi, run: nil, stop: nil) }

  before { allow(SonicPi).to receive(:running).and_return(server) }

  it "stops what is playing before it starts a song, so the form begins at the top" do
    Player.play("play 60")
    expect(server).to have_received(:stop).ordered
    expect(server).to have_received(:run).with("set :stage_loop, false\nplay 60").ordered
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

  describe "the loop" do
    after { Player.looping = false }

    it "is off until switched on" do
      expect(Player.looping).to be(false)
    end

    it "tells the conductor when it is switched" do
      Player.loop(true)
      expect(server).to have_received(:run).with("set :stage_loop, true")
      expect(Player.looping).to be(true)
    end

    it "is remembered even when Sonic Pi is closed, for the next song" do
      allow(SonicPi).to receive(:running).and_return(nil)
      Player.loop(true)
      expect(Player.looping).to be(true)
    end

    it "goes along with every song that starts" do
      Player.looping = true
      Player.play("play 60")
      expect(server).to have_received(:run).with("set :stage_loop, true\nplay 60")
    end
  end

  describe "recording" do
    before { allow(server).to receive(:record) }

    it "stops what plays and records the song once through, without the loop" do
      Player.looping = true
      Player.record("play 60", "/tmp/take.wav", 0)
      expect(server).to have_received(:stop).ordered
      expect(server).to have_received(:record).with("set :stage_loop, false\nplay 60", "/tmp/take.wav").ordered
    ensure
      Player.looping = false
    end
  end
end
