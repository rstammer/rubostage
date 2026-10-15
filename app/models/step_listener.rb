require "socket"
require Rails.root.join("../lib/osc").to_s

# Hears the chord changes Sonic Pi reports (see Groove) and hands them to the
# song's page. Runs as a thread inside the server process, so the in-process
# cable adapter reaches the browsers.
module StepListener
  ADDRESS = "/stage/step"

  module_function

  def start(port)
    Thread.new do
      socket = UDPSocket.new
      socket.bind("127.0.0.1", port)
      loop do
        data, _from = socket.recvfrom(1024)
        Rails.application.executor.wrap { handle(data) }
      end
    rescue Errno::EADDRINUSE
      Rails.logger.warn("StepListener: port #{port} is taken, chords will not follow along")
    end
  end

  def handle(data)
    address, (song_id, index) = OSC.parse(data)
    return unless address == ADDRESS

    song = Song.find_by(id: song_id)
    return unless song&.ready?

    NowPlaying.current_song_id = index.negative? ? nil : song.id
    NowPlaying.broadcast(song, index)
  rescue OSC::Malformed
    nil
  end
end
