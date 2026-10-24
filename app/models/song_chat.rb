# Talks about a song with Claude, as a bandmate would: it knows the sheet,
# the arrangement and the riffs, and the conversation so far. It cannot change
# the song; it says what to put into the editor instead. The lyrics stay out,
# as they do everywhere Claude is asked.
class SongChat
  PROMPT = <<~TEXT
    You are a bandmate of a busker who plays guitar and sings along to a
    backing track. The track is played by Sonic Pi from the song below. Talk
    with them about the song: its chords, form, feel and arrangement. Answer
    in German, short and to the point, like at a rehearsal.

    You cannot change the song yourself. When you suggest a change, say
    exactly what to put into the editor: chords per section, the form, key,
    tempo or bar, the band's parts per section, or a wish to type in for
    "Neu arrangieren".

    The song: %<song>s, %<bpm>s BPM, key %<key>s, %<bar>s.
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

  def initialize(song, client: ClaudeCli.new)
    @song = song
    @client = client
  end

  def call
    @client.call(prompt)
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
