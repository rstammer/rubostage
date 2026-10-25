# Brings a changed song into Sonic Pi while it plays: the new voices take
# over from the next part on, as long as the conductor can keep its place,
# that is with the same tempo and parts of the same length.
module LiveSwap
  module_function

  # :idle when the song is not playing, :restart when it must be started
  # again to be heard, :broken with the code's problems, :swapped when the
  # change is on its way in.
  def call(song, swappable:)
    return [:idle] unless NowPlaying.current_song_id == song.id
    return [:restart] unless swappable

    code = song.voices_code
    problems = CodeCheck.problems(code)
    return [:broken, problems] if problems.any?

    Player.upgrade(code)
    [:swapped]
  rescue Player::NotRunning
    [:idle]
  end
end
