# Stage two: asks for the full arrangement and, when the song is still
# playing, swaps its voices in place. The conductor keeps running, so the song
# stays where it is in the form and the new sound comes in at a section
# boundary. A wish may come along ("quieter, reggae in the chorus"), and a
# song that already has an arrangement keeps it if the new one fails.
class ArrangeSongJob < ApplicationJob
  def perform(song, wish: nil)
    song.update!(arrangement_status: "pending")
    arrangement = ArrangementWriter.new.call(song.lead_sheet, wish: wish)
    song.update!(arrangement: arrangement.to_h, arrangement_status: "ready")
    song.rebuild_code!
    upgrade(song) if NowPlaying.current_song_id == song.id
  rescue Arrangement::Invalid, ClaudeCli::Failed => e
    Rails.logger.warn("Arrangement for song #{song.id} failed: #{e.message}")
    song.update!(arrangement_status: song.arrangement.present? ? "ready" : "failed")
  end

  private

  def upgrade(song)
    code = song.voices_code
    raise Arrangement::Invalid, CodeCheck.problems(code).join("; ") if CodeCheck.problems(code).any?

    Player.upgrade(code)
  rescue Player::NotRunning
    nil
  end
end
