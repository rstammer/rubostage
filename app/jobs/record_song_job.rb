# "WAV aufnehmen": plays the song through in Sonic Pi and keeps the take for
# download. Takes as long as the song does.
class RecordSongJob < ApplicationJob
  def perform(song)
    song.recording_path.dirname.mkpath
    Player.record(song.playable_code, song.recording_path.to_s, song.recording_seconds)
    song.update!(recording_status: song.recording_path.exist? ? "ready" : "failed")
  rescue Player::NotRunning
    song.update!(recording_status: "failed")
  end
end
