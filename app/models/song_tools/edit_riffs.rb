# Changes the riffs: how the guitar riffs sound, the tuning the tabs are
# fretted in, and the guitar and bass tab of each section.
class SongTools::EditRiffs < SongTools::Tool
  include SongTools::ThroughEditor

  define(
    name: "edit_riffs",
    description: "Change the riffs. tone is how guitar riffs sound (crunch = distorted, clean); tuning is " \
      "what the tabs are fretted in. A guitar tab has six lines, high string on top, a bass tab four; " \
      "each bar is sixteen characters between two \"|\": a number is a fret, \"x\" a muted note, \"-\" lets " \
      "it ring. A riff repeats until its section ends; a bass tab silences the bass line in its section. " \
      "An empty tab removes it. The busker can undo every change.",
    input_schema: {
      type: "object",
      properties: {
        summary: {type: "string", description: "What the change does, in a few German words, for the undo button."},
        tone: {type: "string", enum: RiffTrack::TONES},
        tuning: {type: "string", enum: Tab::TUNINGS.keys},
        sections: {
          type: "array",
          items: {
            type: "object",
            properties: {name: {type: "string"}, tab: {type: "string"}, bass_tab: {type: "string"}},
            required: ["name"]
          }
        }
      },
      required: ["summary"]
    }
  )

  def call(song, args)
    check(args["tone"], RiffTrack::TONES, "tone")
    check(args["tuning"], Tab::TUNINGS.keys, "tuning")
    change = save_through_editor(song, args["summary"].presence || "Riffs geändert") do |params, rows|
      params.merge!(args.slice("tone", "tuning"))
      Array(args["sections"]).each do |section|
        row = row_named(rows, section["name"])
        row.merge!(section.slice("tab", "bass_tab").transform_values(&:to_s))
      end
    end
    changed(change)
  end

  private

  def check(value, allowed, name)
    return if value.nil? || allowed.include?(value)

    raise SongTools::Error, "#{name} cannot be #{value.inspect}, only #{allowed.join(", ")}"
  end
end
