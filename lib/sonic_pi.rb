# frozen_string_literal: true

# Talks OSC to a running Sonic Pi server. Started out in mcblinded's bin/play.
#
# Why not the spx gem: it is written against Sonic Pi 4.5 and breaks twice on 5.0.
# It reads the port and token by grepping ~/.sonic-pi/log/spider.log for "Token:"
# and ":server_port=>", and Sonic Pi 5 writes neither line. And it sends to
# "localhost", which resolves to ::1 first on macOS, while the server binds
# 127.0.0.1 only — so the packets vanish without an error.
#
# Port and token change on every Sonic Pi restart, so they are read fresh from
# the spider-server process arguments each time.

require "digest"
require "socket"
require "tmpdir"

class SonicPi
  HOST = "127.0.0.1" # not "localhost": the server is IPv4-only, see above

  def self.running
    line = `ps -Ao args=`.lines.find do |l|
      l.include?("spider-server.rb") && !l.include?("ps -Ao")
    end
    return nil unless line

    # spider-server.rb -u <server> <gui> <scsynth> <scsynth_send> <cues> <token>
    args = line.split("spider-server.rb").last.to_s.split
    return nil if args.size < 7

    new(args[1].to_i, args[6].to_i)
  end

  attr_reader :port, :token

  def initialize(port, token)
    @port = port
    @token = token
    @socket = UDPSocket.new
  end

  def send_osc(path, *args)
    @socket.send(OSC.message(path, @token, *args), 0, HOST, @port)
  end

  # macOS drops UDP datagrams over 9216 bytes on loopback (net.inet.udp.maxdgram)
  # with EMSGSIZE. Longer code goes to a file, and Sonic Pi is told to run that.
  INLINE_LIMIT = 8_000

  def run(code)
    return send_osc("/run-code", code) if code.bytesize <= INLINE_LIMIT

    path = File.join(Dir.tmpdir, "rubostage-#{Digest::SHA256.hexdigest(code)[0, 16]}.rb")
    File.write(path, code)
    send_osc("/run-code", "run_file #{path.inspect}")
  end

  def stop = send_osc("/stop-all-jobs")

  def record(code, output)
    send_osc("/start-recording")
    sleep 0.3
    run(code)
    yield if block_given?
    send_osc("/stop-recording")
    sleep 0.3
    send_osc("/save-recording", File.expand_path(output))
    sleep 1.5
  end
end
