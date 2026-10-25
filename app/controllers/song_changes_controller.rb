# "Rückgängig" on a change Claude made: the song goes back to how it was
# before it, and so do the changes made after it.
class SongChangesController < ApplicationController
  def undo
    song = Song.find(params[:song_id])
    song.changes_made.find(params[:id]).undo!
    redirect_back fallback_location: song_path(song)
  end
end
