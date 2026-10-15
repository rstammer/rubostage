# Turns a wish ("Starlight von Muse") into a lead sheet by asking Claude for
# key, tempo, sections and chords as JSON.
class SheetWriter
  PROMPT = <<~TEXT
    You write lead sheets for a busker who plays guitar and sings along to a
    backing track. Someone has wished for this song:

      %<wish>s

    Answer with JSON only, in exactly this shape:

      {
        "title": "...", "artist": "...",
        "key": "B",
        "bpm": 122,
        "sections": [
          {"name": "Verse", "bars": [["B"], ["C#m"], ["G#m"], ["E", "F#"]]}
        ],
        "form": ["Intro", "Verse", "Chorus", "Verse", "Chorus", "Outro"]
      }

    Rules:
    - Chords as the song is commonly played, in the original key, one bar of
      4/4 per entry; a bar holds one chord or two that split it in half.
    - Chord symbols like C, C#m, Bb7, Fmaj7, Dsus4, A/C#. Nothing else in a bar.
    - "bpm" is a whole number. "form" lists section names in playing order and
      may repeat them; every name must be one of the sections.
    - Keep each section to the bars it really has, at most 16.
    - No lyrics, no melody, no tabs — only form, key, tempo and chords.
    - If the wish is ambiguous, pick the best-known song that fits.
  TEXT

  def initialize(client: ClaudeCli.new)
    @client = client
  end

  def call(wish)
    SongSheet.parse(@client.call(format(PROMPT, wish: wish)))
  end
end
