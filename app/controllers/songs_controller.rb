class SongsController < ApplicationController
  def index
    @song = Song.new
    @songs = Song.newest_first
  end

  def new
    @song = Song.new(origin: "manual")
    @editor = SongEditor.blank(@song)
  end

  def create
    return create_manual if params.dig(:song, :origin) == "manual"

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

  def edit
    @song = Song.find(params[:id])
    return redirect_to(@song) unless @song.ready?

    @editor = SongEditor.for(@song)
  end

  def update
    @song = Song.find(params[:id])
    @editor = SongEditor.new(@song, edit_params)
    if @editor.save
      redirect_to @song, notice: apply_while_playing
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    song = Song.find(params[:id])
    stop_if_playing(song)
    NowPlaying.started_song_id = nil if NowPlaying.started_song_id == song.id
    SongExport.new(song).remove if song.ready?
    FileUtils.rm_f(song.recording_path)
    song.destroy!
    redirect_to root_path, notice: "#{song.display_title} ist gelöscht."
  end

  private

  # A sheet written by hand: stored as it is, no Claude involved.
  def create_manual
    @song = Song.new(origin: "manual")
    @editor = SongEditor.new(@song, edit_params)
    if @editor.save
      redirect_to @song, notice: "Gespeichert."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit_params
    params.require(:song).permit(:title, :artist, :key, :bpm, :beats, :form, :tuning, :tone, :lyrics,
      sections: [:original, :name, :chords, :energy, :groove, :guitar, :swing, :fill, :riff_guitar, :tab, :riff_bass, :bass_tab])
  end

  def apply_while_playing
    outcome, problems = LiveSwap.call(@song, swappable: @editor.swappable?)
    {
      idle: "Gespeichert.",
      restart: "Gespeichert. Tempo oder Länge eines Teils hat sich geändert – zum Hören neu starten.",
      broken: "Gespeichert, aber der Code hat Fehler: #{problems&.join("; ")}",
      swapped: "Gespeichert – klingt ab dem nächsten Teil."
    }.fetch(outcome)
  end

  def stop_if_playing(song)
    return unless NowPlaying.current_song_id == song.id

    NowPlaying.current_song_id = nil
    Player.stop
  rescue Player::NotRunning
    nil
  end
end
