# A question in the editor's conversation about the song. Claude answers in
# the background; the answer arrives over the song's chat stream.
class SongMessagesController < ApplicationController
  def create
    @song = Song.find(params[:song_id])
    body = params.dig(:message, :body).to_s.strip
    @asked = body.present?
    if @asked
      @song.messages.create!(role: "user", body: body)
      SongChatJob.perform_later(@song)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to edit_song_path(@song, anchor: "chat") }
    end
  end
end
