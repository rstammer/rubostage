class SongsController < ApplicationController
  def index
    @song = Song.new
    @songs = Song.newest_first
  end

  def create
    @song = Song.new(request: params.dig(:song, :request).to_s.strip)
    if @song.save
      GenerateSongJob.perform_later(@song)
      redirect_to @song
    else
      @songs = Song.newest_first
      render :index, status: :unprocessable_content
    end
  end

  def show
    @song = Song.find(params[:id])
  end
end
