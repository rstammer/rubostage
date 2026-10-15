require Rails.root.join("../lib/sonic_pi").to_s

# The app's way to Sonic Pi, through the same client bin/play uses.
module Player
  class NotRunning < StandardError; end

  module_function

  def play(code)
    server.run(code)
  end

  def stop
    server.stop
  end

  def running?
    !SonicPi.running.nil?
  end

  def server
    SonicPi.running || raise(NotRunning, "Sonic Pi läuft nicht")
  end
end
