# Wish in, play-along out: asks for the sheet, builds the groove, checks the
# code and starts it straight away.
class GenerateSongJob < ApplicationJob
  def perform(song)
    sheet = SheetWriter.new.call(song.request)
    code = Groove.new(sheet).code
    problems = CodeCheck.problems(code)
    raise SongSheet::Invalid, problems.join("; ") if problems.any?

    song.update!(
      title: sheet.title, artist: sheet.artist, key: sheet.key, bpm: sheet.bpm,
      sheet: sheet.to_h, code: code, status: "ready", error: nil
    )
    play(song)
  rescue SongSheet::Invalid, ClaudeCli::Failed => e
    song.update!(status: "failed", error: e.message)
  end

  private

  # Sonic Pi being closed is no reason to lose the song: it stays ready and
  # can be started from the page.
  def play(song)
    Player.play(song.code)
  rescue Player::NotRunning
    nil
  end
end
