# Stops Sonic Pi, as the stop footswitch does.
class SongTools::Stop < SongTools::Tool
  define(
    name: "stop",
    description: "Stop the music.",
    input_schema: {type: "object", properties: {}}
  )

  def call(_song, _args)
    Player.stop
    NowPlaying.current_song_id = nil
    "Stopped."
  rescue Player::NotRunning
    "Sonic Pi is not running, so nothing plays."
  end
end
