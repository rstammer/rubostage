# "Arrangieren lassen" / "Neu arrangieren": the song's sheet, with the player's
# wish if there is one, goes to Claude for a fresh arrangement.
class ArrangementsController < ApplicationController
  def create
    song = Song.find(params[:song_id])
    song.update!(arrangement_status: "pending")
    ArrangeSongJob.perform_later(song, wish: params[:wish].to_s.strip.presence)
    redirect_to song, notice: "Die KI arrangiert – klingt ab dem nächsten Teil, wenn der Song läuft."
  end
end
