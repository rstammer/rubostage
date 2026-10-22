# Repeat, next, jump, end: queued for the groove's conductor, which carries
# them out at the next section boundary.
class CommandsController < ApplicationController
  KINDS = %w[repeat next jump end].freeze

  def create
    song = Song.find(params[:song_id])
    kind = params[:kind].to_s
    position = params[:position].presence&.to_i
    form = song.lead_sheet.form

    return head :unprocessable_content unless valid?(kind, position, form)

    Player.command(kind.to_sym, position)
    render_queued note_for(kind, form, position)
  rescue Player::NotRunning
    render_queued "Sonic Pi läuft nicht – erst öffnen: open -a \"Sonic Pi\""
  end

  private

  def valid?(kind, position, form)
    return false unless KINDS.include?(kind)

    kind != "jump" || (0...form.size).cover?(position)
  end

  def note_for(kind, form, position)
    case kind
    when "repeat" then "Vorgemerkt: Teil wiederholen"
    when "next" then "Vorgemerkt: weiter zum nächsten Teil"
    when "jump" then "Vorgemerkt: als Nächstes #{form[position]}"
    when "end" then "Vorgemerkt: nach diesem Teil Schluss"
    end
  end

  # On the song's page and in the transport bar, whichever is there.
  def render_queued(note)
    render turbo_stream: [turbo_stream.update("queued", note), turbo_stream.update("bar_queued", note)]
  end
end
