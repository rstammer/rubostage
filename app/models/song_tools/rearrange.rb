# Has the band written anew, as "Neu arrangieren" does, with a wish. That
# takes a while, so it runs in the background; the new arrangement arrives
# as a change in the chat that can be taken back.
class SongTools::Rearrange < SongTools::Tool
  define(
    name: "rearrange",
    description: "Have the whole band arrangement written anew from scratch, following a wish. Takes a " \
      "minute or two and replaces every section's part; for a targeted change use edit_band instead. " \
      "The result appears in the chat with an undo button.",
    input_schema: {
      type: "object",
      properties: {
        summary: {type: "string", description: "What the new arrangement is for, in a few German words, for the undo button."},
        wish: {type: "string", description: "What the new arrangement should be like, e.g. \"ruhiger, Reggae im Refrain\"."}
      },
      required: ["summary"]
    }
  )

  def call(song, args)
    raise SongTools::Error, "an arrangement is already being written for this song" if song.arrangement_status == "pending"

    song.update!(arrangement_status: "pending")
    ArrangeSongJob.perform_later(song, wish: args["wish"].to_s.strip.presence, summary: args["summary"].presence || "Neu arrangiert")
    "Started. The new arrangement takes a minute or two; it swaps in when ready and shows up in the chat with an undo button."
  end
end
