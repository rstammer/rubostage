class ExportsController < ApplicationController
  def create
    song = Song.find(params[:song_id])
    export = SongExport.new(song).call
    redirect_to song, notice: "Liegt jetzt in #{export.path} – committen machst du."
  rescue SongExport::HandWritten => e
    redirect_to song, alert: "#{e.message} ist von Hand geschrieben – bleibt, wie es ist."
  end
end
