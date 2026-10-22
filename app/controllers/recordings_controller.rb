class RecordingsController < ApplicationController
  def create
    song = Song.find(params[:song_id])
    song.update!(recording_status: "pending")
    RecordSongJob.perform_later(song)
    redirect_to song
  end

  def show
    song = Song.find(params[:song_id])
    return head :not_found unless song.recording_path.exist?

    send_file song.recording_path, filename: song.recording_filename, type: "audio/wav", disposition: "attachment"
  end
end
