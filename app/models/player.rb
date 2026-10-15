require Rails.root.join("../lib/sonic_pi").to_s

# The app's way to Sonic Pi, through the same client bin/play uses.
module Player
  class NotRunning < StandardError; end

  COMMANDS = %i[repeat next jump end].freeze

  module_function

  # Stops whatever runs first, so a song always starts at the top of its form
  # rather than inside the conductor state of the one before.
  def play(code)
    sonic_pi = server
    sonic_pi.stop
    sonic_pi.run(code)
  end

  def stop
    server.stop
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
