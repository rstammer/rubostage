# Asks Claude how a band would play the sheet: sounds and sixteen-step
# patterns per section, as JSON that Arrangement reads.
class ArrangementWriter
  PROMPT = <<~TEXT
    You arrange backing tracks for a busker who plays guitar and sings along.
    The song: %<song>s, %<bpm>s BPM, key %<key>s.

    Sections and their chords, one bar of 4/4 per entry:
    %<sections>s

    Write a backing arrangement that captures the song's genre, feel and
    dynamics — the drum style, how hard the band plays, where it drops and
    where it explodes. Use your own patterns, not a transcription of the
    record's parts. Answer with JSON only, in exactly this shape:

      {
        "sounds": {"bass": "fm", "comp": "pulse", "pad": "hollow", "distorted": true},
        "sections": {
          "<section name>": {
            "energy": 2,
            "groove": "rock",
            "swing": 0,
            "fill": false,
            "guitar": "power",
            "comp": "x.x.x.x.x.x.x.x.",
            "bass": "1.1.1.1.1.1.1.15",
            "pad": false
          }
        }
      }

    Rules:
    - "groove" is the drum style, one of %<grooves>s. halftime puts the
      backbeat on three; shuffle swings; four_floor is a kick on every beat.
    - "swing" 0 to 0.33 delays the offbeat eighths; 0 for straight songs.
    - "fill" true plays a tom fill in the section's last two beats, e.g. into
      a chorus.
    - "guitar" is how the guitar part plays: %<guitars>s. power = distorted
      power chords, palm = muted chugs, strum = clean open chords, stabs =
      short chords, none = guitar out.
    - "comp" is the guitar's rhythm, "bass" the bass line: 16 characters each,
      one per sixteenth note, repeated every bar. comp uses "x" or "."; bass
      uses "1" (root), "5" (fifth), "8" (octave) or ".".
    - "energy" is 1 (quiet), 2 or 3 (full). Make the contrast real: a quiet
      verse and a loud chorus should sound very different.
    - Sounds: bass one of %<bass>s; comp (for stabs) one of %<comp>s; pad one
      of %<pad>s; "distorted" true for rock songs.
    - One entry per section name above. No lyrics, no melodies, no riffs.
  TEXT

  WISH = <<~TEXT

    The busker has a wish for this arrangement. Follow it as far as the
    rules above allow:
    %<wish>s
  TEXT

  def initialize(client: ClaudeCli.new)
    @client = client
  end

  def call(sheet, wish: nil)
    Arrangement.parse(@client.call(prompt_for(sheet, wish.to_s.strip)), sheet)
  end

  private

  def prompt_for(sheet, wish)
    sections = sheet.sections.map do |section|
      "  #{section.name}: #{section.bars.map { |bar| bar.join(" ") }.join(" | ")}"
    end
    song = sheet.artist.present? ? "#{sheet.title} by #{sheet.artist}" : "#{sheet.title}, the busker's own song"
    prompt = format(
      PROMPT,
      song: song, bpm: sheet.bpm, key: sheet.key,
      sections: sections.join("\n"),
      grooves: DrumGroove::NAMES.join(", "),
      guitars: Arrangement::Part::GUITARS.join(", "),
      bass: Arrangement::SOUNDS[:bass].join(", "),
      comp: Arrangement::SOUNDS[:comp].join(", "),
      pad: Arrangement::SOUNDS[:pad].join(", ")
    )
    wish.empty? ? prompt : prompt + format(WISH, wish: wish)
  end
end
