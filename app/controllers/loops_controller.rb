# The "Endlos" footswitch: latches the loop on or off, also while a song plays.
class LoopsController < ApplicationController
  def update
    @song = Song.find(params[:song_id])
    Player.loop(params[:on] == "1")
    render turbo_stream: turbo_stream.replace("loop_switch", partial: "songs/loop_switch", locals: {song: @song})
  end
end
