# Asks Claude how a band would play the sheet: sounds and sixteen-step
# patterns per section, as JSON that Arrangement reads.
class ArrangementWriter
  PROMPT = <<~TEXT
    You arrange backing tracks for a busker who plays guitar and sings along.
    The song: %<title>s by %<artist>s, %<bpm>s BPM, key %<key>s.

    Sections and their chords, one bar of 4/4 per entry:
    %<sections>s

    Write a backing arrangement in the spirit of the song's style and energy —
    your own patterns, not a transcription of the record's parts. Answer with
    JSON only, in exactly this shape:

      {
        "sounds": {"bass": "tb303", "comp": "pulse", "pad": "hollow", "distorted": false},
        "sections": {
          "<section name>": {
            "energy": 2,
            "kick":     "x.......x.x.....",
            "snare":    "....x.......x...",
            "hat":      "x.x.x.x.x.x.x.x.",
            "open_hat": "..............x.",
            "bass":     "1..1..5.1..1..8.",
            "comp":     "x..x..x.........",
            "pad": true
          }
        }
      }

    Rules:
    - Every pattern is exactly 16 characters, one per sixteenth note of a bar,
      and repeats for every bar of the section.
    - Drum and comp patterns use "x" for a hit and "." for a rest.
    - The bass pattern uses "1" (root), "5" (fifth), "8" (octave) or ".".
    - "energy" is 1 (quiet), 2 or 3 (full); let it follow the song's dynamics.
    - Sounds: bass one of %<bass>s; comp one of %<comp>s; pad one of %<pad>s;
      "distorted" true for rock songs that want a distorted comp.
    - One entry per section name above. No lyrics, no melodies.
  TEXT

  def initialize(client: ClaudeCli.new)
    @client = client
  end

  def call(sheet)
    Arrangement.parse(@client.call(prompt_for(sheet)), sheet)
  end

  private

  def prompt_for(sheet)
    sections = sheet.sections.map do |section|
      "  #{section.name}: #{section.bars.map { |bar| bar.join(" ") }.join(" | ")}"
    end
    format(
      PROMPT,
      title: sheet.title, artist: sheet.artist, bpm: sheet.bpm, key: sheet.key,
      sections: sections.join("\n"),
      bass: Arrangement::SOUNDS[:bass].join(", "),
      comp: Arrangement::SOUNDS[:comp].join(", "),
      pad: Arrangement::SOUNDS[:pad].join(", ")
    )
  end
end
