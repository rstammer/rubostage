# The app's way to Sonic Pi, through the SonicPi client in lib/.
module Player
  class NotRunning < StandardError; end

  COMMANDS = %i[repeat next jump end].freeze

  # The loop switch stays where it is put, like a latching footswitch, and
  # lives in the server process. Sonic Pi forgets it on a restart, so every
  # song that starts takes it along.
  @looping = false

  class << self
    attr_accessor :looping
  end

  module_function

  # Stops whatever runs first, so a song always starts at the top of its form
  # rather than inside the conductor state of the one before.
  def play(code)
    sonic_pi = server
    sonic_pi.stop
    sonic_pi.run("set :stage_loop, #{Player.looping}\n#{code}")
  end

  # On: at the end of the form the conductor starts again from the top
  # instead of the closing chord. "end" still ends the song.
  def loop(on)
    Player.looping = on
    server.run("set :stage_loop, #{on}")
  rescue NotRunning
    nil
  end

  def stop
    server.stop
  end

  # Runs code next to what plays, without stopping it: redefined live_loops
  # take over at their next pass.
  def upgrade(code)
    server.run(code)
  end

  # Queues a command for the groove's conductor, which reads it at the next
  # section boundary. The number in front tells a new command from one it has
  # already handled.
  def command(kind, position = nil)
    raise ArgumentError, "unknown command: #{kind}" unless COMMANDS.include?(kind)

    server.run("set :stage_cmd, [#{(Time.now.to_f * 1000).to_i}, :#{kind}, #{position.nil? ? "nil" : Integer(position)}]")
  end

  def running?
    !SonicPi.running.nil?
  end

  def server
    SonicPi.running || raise(NotRunning, "Sonic Pi läuft nicht")
  end
end
