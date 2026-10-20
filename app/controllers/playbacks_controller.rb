class PlaybacksController < ApplicationController
  rescue_from Player::NotRunning do
    redirect_back_or_to root_path, alert: "Sonic Pi läuft nicht – oben in der Leiste starten."
  end

  def create
    song = Song.find(params[:song_id])
    Player.play(song.playable_code)
    redirect_to song
  end

  def destroy
    Player.stop
    NowPlaying.current_song_id = nil
    redirect_back_or_to root_path
  end
end
