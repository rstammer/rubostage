# "Code neu bauen": a song keeps its code, so a better groove only reaches
# it when asked for.
class CodesController < ApplicationController
  def create
    song = Song.find(params[:song_id])
    song.rebuild_code!
    redirect_to song, notice: "Code neu gebaut – klingt so ab dem nächsten Start."
  end
end
