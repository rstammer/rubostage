# What the lamps in the control bar show: whether Sonic Pi is there, which
# song plays, and whether the AI is writing something.
class ControlPanel
  # Sonic Pi reports every chord, so a few seconds without one means the song
  # was stopped or Sonic Pi went away.
  STEP_TIMEOUT = 3.seconds

  # A job that has not finished by then has died with the server.
  JOB_TIMEOUT = 10.minutes

  def sonic_pi
    @sonic_pi ||= SonicPiApp.state
  end

  def song
    return unless NowPlaying.current_song_id && NowPlaying.last_step_at&.after?(STEP_TIMEOUT.ago)

    Song.find_by(id: NowPlaying.current_song_id)
  end

  # The song the transport bar steers: the last one started, for as long as
  # Sonic Pi is there to play it.
  def started
    return unless NowPlaying.started_song_id && sonic_pi == :ready

    Song.find_by(id: NowPlaying.started_song_id)
  end

  def thinking?
    Song.where(updated_at: JOB_TIMEOUT.ago..)
      .where(status: "pending").or(Song.where(updated_at: JOB_TIMEOUT.ago.., arrangement_status: "pending"))
      .exists?
  end
end
