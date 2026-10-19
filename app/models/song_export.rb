# Takes a song from the stage into the repo, as songs/<song>/live.rb and
# NOTES.md, so it plays with bin/play and lives on without the app.
#
# Both files carry a mark in their first line. A file with the mark came from
# here and is overwritten by the next export; a file without it was written by
# hand and is never touched. Taking the mark out is how a song leaves the
# stage for good.
class SongExport
  class HandWritten < StandardError; end

  MARK = "# Exported from the mcblinded stage."
  MARK_MD = "<!-- Exported from the mcblinded stage."
  FILES = %w[live.rb NOTES.md].freeze

  def self.default_root
    Rails.application.config.x.songs_root
  end

  def initialize(song, root: self.class.default_root)
    @song = song
    @sheet = song.lead_sheet
    @root = Pathname(root)
  end

  def dir
    @root.join(@sheet.title.parameterize(separator: "_"))
  end

  # The folder as the repo knows it, e.g. "songs/starlight".
  def path
    "songs/#{dir.basename}"
  end

  def call
    hand_written = FILES.find { |name| hand_written?(dir.join(name)) }
    raise HandWritten, "#{path}/#{hand_written}" if hand_written

    dir.mkpath
    dir.join("live.rb").write(live_rb)
    dir.join("NOTES.md").write(notes_md)
    self
  end

  private

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

    RUBY
  end

  def notes_md
    [header, facts, chords, arrangement, riffs, playing].compact.join("\n")
  end

  def header
    <<~MD
      #{MARK_MD} The next export overwrites this file; to work on it by hand, take this line out first. -->
      # #{@sheet.title}

      Cover von **#{@sheet.artist} — „#{@sheet.title}"**, aus der mcblinded-Stage übernommen.

      > Tonart, Tempo, Form und Akkorde hat die KI aus dem Gedächtnis geschrieben —
      > **ungeprüft**, nach Gehör gegenchecken. Der Songtext liegt bewusst nicht im Repo.
    MD
  end

  def facts
    <<~MD
      ## Eckdaten

      - **Tonart:** #{@sheet.key}
      - **Tempo:** #{@sheet.bpm} BPM
      - **Form:** #{@sheet.form.join(" – ")}
    MD
  end

  def chords
    rows = @sheet.sections.map do |section|
      bars = section.bars.map { |bar| bar.join(" ") }.join(" \\| ")
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

    tabs = track.tabs.map { |name, text| "### #{name}\n\n```text\n#{text.strip}\n```\n" }
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
