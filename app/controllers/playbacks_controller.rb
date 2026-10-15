class PlaybacksController < ApplicationController
  rescue_from Player::NotRunning do
    redirect_back_or_to root_path, alert: "Sonic Pi läuft nicht – erst öffnen: open -a \"Sonic Pi\""
  end

  def create
    song = Song.find(params[:song_id])
    Player.play(song.code)
    redirect_to song
  end

  def destroy
    Player.stop
    redirect_back_or_to root_path
  end
end
