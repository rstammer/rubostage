# Puts a song into the songs folder as <songs>/<song>/live.rb and NOTES.md, so
# it plays with bin/play and lives on without the app. The folder is meant to
# be a repo of its own; rubostage writes files and leaves git alone.
#
# Both files carry a mark in their first line. A file with the mark came from
# here and is overwritten by the next export; a file without it was written by
# hand and is never touched. Taking the mark out is how a song leaves the
# stage for good.
#
# Each song keeps the name of its folder from its first export, so a new
# title does not scatter its history, and two songs of the same title do not
# write over each other.
class SongExport
  class HandWritten < StandardError; end

  MARK = "# Exported from rubostage."
  MARK_MD = "<!-- Exported from rubostage."
  FILES = %w[live.rb NOTES.md].freeze

  def self.default_root
    Setting.songs_root
  end

  # After the folder has moved: every finished song goes there, except where
  # a song has been taken over by hand.
  def self.mirror_all(root: default_root)
    Song.where(status: "ready").find_each do |song|
      new(song, root: root).call
    rescue HandWritten
      next
    end
  end

  def initialize(song, root: self.class.default_root)
    @song = song
    @sheet = song.lead_sheet
    @root = Pathname(root)
  end

  def dir
    @root.join(@song.folder || free_folder)
  end

  # The folder as the songs repo knows it, e.g. "songs/starlight".
  def path
    "#{@root.basename}/#{dir.basename}"
  end

  def call
    claim_folder
    hand_written = FILES.find { |name| hand_written?(dir.join(name)) }
    raise HandWritten, "#{path}/#{hand_written}" if hand_written

    dir.mkpath
    dir.join("live.rb").write(live_rb)
    dir.join("NOTES.md").write(notes_md)
    self
  end

  # Takes back what the export wrote, and the folder if nothing else is left.
  def remove
    return unless @song.folder && dir.directory?

    FILES.map { |name| dir.join(name) }.select { |file| file.exist? && !hand_written?(file) }.each(&:delete)
    dir.rmdir if dir.empty?
  end

  # Whether the song lies in the folder as the export wrote it.
  def exported?
    @song.folder.present? && FILES.all? { |name| dir.join(name).exist? && !hand_written?(dir.join(name)) }
  end

  private

  def claim_folder
    @song.update_column(:folder, free_folder) unless @song.folder
  end

  # The title as a folder name, numbered on when another song has it or a
  # folder of that name holds a song written by hand.
  def free_folder
    base = @sheet.title.parameterize(separator: "_").presence || "song"
    return base if free?(base)

    (2..).lazy.map { |n| "#{base}_#{n}" }.find { |name| free?(name) }
  end

  def free?(name)
    return false if Song.where(folder: name).where.not(id: @song.id).exists?

    FILES.none? { |file| hand_written?(@root.join(name, file)) }
  end

  def hand_written?(file)
    file.exist? && !file.read.start_with?(MARK, MARK_MD)
  end

  # Without a song id the groove does not report to the stage, so it runs
  # with nothing listening.
  def live_rb
    groove = Groove.new(@sheet, arrangement: @song.full_arrangement, riffs: @song.riffs)
    <<~RUBY + groove.code
      #{MARK} The next export overwrites this file;
      # to work on it by hand, take this line out first.
      #
      #   bin/play #{path}/live.rb
      #
      # The form plays through by itself. Commands land at the next section
      # boundary; each needs a new first number:
      #
      #   bin/play -e 'set :stage_cmd, [2, :repeat, nil]'
      #   bin/play -e 'set :stage_cmd, [3, :next, nil]'
      #   bin/play -e 'set :stage_cmd, [4, :jump, 0]'
      #   bin/play -e 'set :stage_cmd, [5, :end, nil]'
      #
      # To loop the form instead of ending it:
      #
      #   bin/play -e 'set :stage_loop, true'

    RUBY
  end

  def notes_md
    [header, facts, chords, arrangement, riffs, playing].compact.join("\n")
  end

  def header
    mark = "#{MARK_MD} The next export overwrites this file; to work on it by hand, take this line out first. -->"
    return "#{mark}\n# #{@sheet.title}\n\nEigener Song, in rubostage geschrieben.\n" if @song.manual?

    <<~MD
      #{mark}
      # #{@sheet.title}

      Cover von **#{@sheet.artist} — „#{@sheet.title}"**, aus rubostage übernommen.

      > Tonart, Tempo, Form und Akkorde hat die KI aus dem Gedächtnis geschrieben —
      > **ungeprüft**, nach Gehör gegenchecken. Der Songtext liegt bewusst nicht im Repo.
    MD
  end

  def facts
    <<~MD
      ## Eckdaten

      - **Tonart:** #{@sheet.key}
      - **Tempo:** #{@sheet.bpm} BPM
      - **Takt:** #{@sheet.beats}/4
      - **Form:** #{@sheet.form.join(" – ")}
    MD
  end

  def chords
    rows = @sheet.sections.map do |section|
      # Escaped, or the bar lines would split the Markdown table.
      bars = section.chart.gsub("|") { "\\|" }
      "| #{section.name} | `#{bars}` |"
    end
    <<~MD
      ## Akkorde

      Ein Takt zwischen den Strichen, zwei Akkorde teilen ihn sich.

      | Teil | Takte |
      |---|---|
      #{rows.join("\n")}
    MD
  end

  def arrangement
    arranged = @song.full_arrangement
    return unless arranged

    sounds = arranged.sounds
    rows = @sheet.sections.map do |section|
      part = arranged.section(section.name)
      "| #{section.name} | #{part.energy} | #{part.groove} | #{part.guitar} | #{part.swing.round(2)} | #{part.fill ? "ja" : "–"} |"
    end
    <<~MD
      ## Arrangement

      Bass `#{sounds[:bass]}`, Begleitung `#{sounds[:comp]}`, Fläche `#{sounds[:pad]}`#{", verzerrt" if sounds[:distorted]}.

      | Teil | Energie | Groove | Gitarre | Swing | Fill |
      |---|---|---|---|---|---|
      #{rows.join("\n")}
    MD
  end

  def riffs
    track = @song.riffs
    return if track.nil? || track.empty?

    tabs = track.tabs.map { |name, text| "### #{name}\n\n```text\n#{text.strip}\n```\n" } +
      track.bass_tabs.map { |name, text| "### #{name} (Bass)\n\n```text\n#{text.strip}\n```\n" }
    <<~MD
      ## Riffs

      Stimmung `#{track.tuning}`, Klang `#{track.tone}`.

      #{tabs.join("\n")}
    MD
  end

  def playing
    <<~MD
      ## Abspielen

      ```bash
      bin/play #{path}/live.rb
      bin/play --stop
      ```

      Befehle für Wiederholen, Weiter, Springen und Schluss stehen oben in `live.rb`.
    MD
  end
end
