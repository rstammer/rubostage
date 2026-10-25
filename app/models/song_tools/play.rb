# Starts the song in Sonic Pi, as the play footswitch does.
class SongTools::Play < SongTools::Tool
  define(
    name: "play",
    activity: "startet den Song",
    description: "Start the song in Sonic Pi from the top, so the busker hears it.",
    input_schema: {type: "object", properties: {}}
  )

  def call(song, _args)
    Player.play(song.playable_code)
    NowPlaying.started_song_id = song.id
    "Playing from the top."
  rescue Player::NotRunning
    raise SongTools::Error, "Sonic Pi is not running; the busker can start it from the lamp in the top bar."
  end
end
