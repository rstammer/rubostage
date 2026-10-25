# Talks about a song with Claude, as a bandmate would: it knows the sheet,
# the arrangement and the riffs, and the conversation so far, and changes the
# song with the song tools when asked. Every change can be taken back. The
# lyrics stay out, as they do everywhere Claude is asked.
class SongChat
  PROMPT = <<~TEXT
    You are a bandmate of a busker who plays guitar and sings along to a
    backing track. The track is played by Sonic Pi from the song below. Talk
    with them about the song: its chords, form, feel and arrangement. Answer
    in German, short and to the point, like at a rehearsal.

    You can change the song with your tools: edit_sheet for key, tempo, bar,
    form and chords; edit_band for the sounds and how the band plays each
    section; edit_riffs for the riffs' tone, tuning and tabs; rearrange to
    have the whole band written anew from a wish, which takes a minute or
    two. play and stop start and stop the music, e.g. to hear a change.
    When they ask for a change, make it, then say in a sentence or two what
    you changed; give each change a short German summary. A tool tells you
    whether the change is heard right away or needs a new start; pass that
    on. The busker can undo any change with a button. When it is unclear
    what they want, ask before changing anything. Musical calls are theirs:
    suggest, do not insist.

    The song as it was when the question came (get_song reads it fresh):
    %<song>s, %<bpm>s BPM, key %<key>s, %<bar>s.
    Sections and their chords:
    %<sections>s
    Form: %<form>s

    Arrangement (JSON, empty when the band plays the plain groove):
    %<arrangement>s

    Riffs as tabs (JSON, empty when there are none):
    %<riffs>s

    The conversation so far, the last line is the question to answer:
    %<conversation>s
  TEXT

  SPEAKERS = {"user" => "Busker", "assistant" => "You"}.freeze

  def initialize(song, client: SongTools::ClaudeCliClient.new)
    @song = song
    @client = client
  end

  # With a block, the answer comes in pieces as it is written; on_tool hears
  # the name of each tool Claude uses.
  def call(on_tool: nil, &on_text)
    @client.call(prompt, toolbox: SongTools::Toolbox.new(@song), on_tool: on_tool, &on_text)
  end

  private

  def prompt
    sheet = @song.lead_sheet
    format(
      PROMPT,
      song: sheet.artist.present? ? "#{sheet.title} by #{sheet.artist}" : "#{sheet.title}, the busker's own song",
      bpm: sheet.bpm, key: sheet.key, bar: "#{sheet.beats}/4",
      sections: sheet.sections.map { |section| "  #{section.name}: #{section.chart}" }.join("\n"),
      form: sheet.form.join(", "),
      arrangement: @song.arrangement.to_json,
      riffs: @song.riff_track.to_json,
      conversation: @song.messages.order(:id).map { |message| "#{SPEAKERS[message.role]}: #{message.body}" }.join("\n")
    )
  end
end
