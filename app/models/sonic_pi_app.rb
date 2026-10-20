# The Sonic Pi app itself, as opposed to its server: whether it is open, and
# opening it. The server comes up 10–20 s after the app, so there is a state
# in between.
module SonicPiApp
  module_function

  def state
    return :ready if SonicPi.running

    processes.include?("Sonic Pi.app/Contents/MacOS/") ? :starting : :off
  end

  # open hands its environment to the app, and Sonic Pi's own Ruby dies at
  # boot on ours (RUBYOPT=-rbundler/setup, GEM_HOME, BUNDLE_GEMFILE): the GUI
  # then reports "Error reading ports via Boot Daemon".
  def launch
    system(without_ruby_env, "open", "-a", "Sonic Pi")
  end

  def without_ruby_env
    ENV.keys.grep(/\A(RUBY|BUNDLE|GEM_)/).index_with(nil)
  end

  def processes
    `ps -Ao args=`
  end
end
