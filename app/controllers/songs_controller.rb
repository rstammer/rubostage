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
    SongExport.new(song).remove if song.ready?
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
    params.require(:song).permit(:title, :artist, :key, :bpm, :beats, :form, :tuning, :tone,
      sections: [:original, :name, :chords, :energy, :groove, :guitar, :swing, :fill, :riff_guitar, :tab, :riff_bass, :bass_tab])
  end

  # A song that is playing hears the change from its next part on, as long
  # as the conductor can keep its place: same tempo, parts of the same length.
  def apply_while_playing
    return "Gespeichert." unless NowPlaying.current_song_id == @song.id
    return "Gespeichert. Tempo oder Länge eines Teils hat sich geändert – zum Hören neu starten." unless @editor.swappable?

    code = @song.voices_code
    return "Gespeichert, aber der Code hat Fehler: #{CodeCheck.problems(code).join("; ")}" if CodeCheck.problems(code).any?

    Player.upgrade(code)
    "Gespeichert – klingt ab dem nächsten Teil."
  rescue Player::NotRunning
    "Gespeichert."
  end

  def stop_if_playing(song)
    return unless NowPlaying.current_song_id == song.id

    NowPlaying.current_song_id = nil
    Player.stop
  rescue Player::NotRunning
    nil
  end
end
