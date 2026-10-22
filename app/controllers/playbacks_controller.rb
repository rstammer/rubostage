class PlaybacksController < ApplicationController
  rescue_from Player::NotRunning do
    redirect_back_or_to root_path, alert: "Sonic Pi läuft nicht – oben in der Leiste starten."
  end

  def create
    song = Song.find(params[:song_id])
    Player.play(song.playable_code)
    NowPlaying.started_song_id = song.id
    redirect_to from_bar? ? transport_path : song
  end

  def destroy
    Player.stop
    NowPlaying.current_song_id = nil
    from_bar? ? redirect_to(transport_path) : redirect_back_or_to(root_path)
  end

  private

  # A press in the transport bar is answered with the bar alone: a frame
  # request gets no layout, so a whole page would leave the bar empty.
  def from_bar?
    turbo_frame_request_id == "transport"
  end
end
