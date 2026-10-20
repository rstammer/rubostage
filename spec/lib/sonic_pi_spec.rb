require "rails_helper"

RSpec.describe SonicPi do
  # Stands in for the Sonic Pi server: a UDP socket on a free local port.
  let(:fake_server) { UDPSocket.new.tap { |s| s.bind("127.0.0.1", 0) } }
  let(:sonic_pi) { described_class.new(fake_server.addr[1], 42) }

  after { fake_server.close }

  def received
    OSC.parse(fake_server.recvfrom(65_535)[0])
  end

  it "sends short code inline" do
    sonic_pi.run("play 60")
    expect(received).to eq(["/run-code", [42, "play 60"]])
  end

  # macOS drops UDP datagrams over 9216 bytes on loopback (EMSGSIZE).
  it "hands long code over as a file" do
    code = "play 60\n" * 2_000
    sonic_pi.run(code)
    address, (token, sent) = received
    expect([address, token]).to eq(["/run-code", 42])
    path = sent[/\Arun_file "(.+)"\z/, 1]
    expect(path).to be_present
    expect(File.read(path)).to eq(code)
  end
end
