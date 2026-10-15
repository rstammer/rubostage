import { Controller } from "@hotwired/stimulus"

const BAR = 16
const LABEL = /^\s*([A-Ga-g][#b]?)?\s*\|/

// Helps type a tab. "+ Takt" adds an empty bar to the last six lines, and
// writes out the strings first when the box is empty. The line under the box
// says how many bars it reads, or what does not fit. The server checks again
// on save; this is only so mistakes show while typing.
export default class extends Controller {
  static targets = ["input", "status"]
  static values = { strings: Array }

  connect() {
    this.check()
  }

  addBar() {
    let lines = this.lines()
    if (lines.length === 0) lines = this.stringsValue.map((name) => `${name}|`)
    if (lines.length % 6 !== 0) return this.check()

    const empty = "-".repeat(BAR) + "|"
    lines = lines.map((line, i) => (i >= lines.length - 6 ? line + empty : line))
    this.inputTarget.value = lines.join("\n") + "\n"
    this.check()
    this.inputTarget.focus()
  }

  check() {
    this.statusTarget.textContent = this.describe(this.lines())
  }

  describe(lines) {
    if (lines.length === 0) return "Kein Riff in diesem Teil."
    if (lines.length % 6 !== 0) return `${lines.length} Zeilen – ein Tab braucht sechs pro Block, eine je Saite.`

    let bars = 0
    for (let start = 0; start < lines.length; start += 6) {
      const counts = []
      for (const line of lines.slice(start, start + 6)) {
        const name = (line.match(LABEL) || [])[1] || "?"
        const parts = line.replace(LABEL, "").split("|").filter((part) => part !== "")
        const wrong = parts.findIndex((part) => part.length !== BAR)
        if (wrong >= 0) return `Saite ${name}, Takt ${wrong + 1}: ${parts[wrong].length} Zeichen, braucht ${BAR}.`
        counts.push(parts.length)
      }
      if (new Set(counts).size > 1) return "Die Saiten haben unterschiedlich viele Takte."
      bars += counts[0]
    }
    return bars === 1 ? "1 Takt" : `${bars} Takte`
  }

  lines() {
    return this.inputTarget.value.split("\n").map((line) => line.trim()).filter((line) => line !== "")
  }
}
