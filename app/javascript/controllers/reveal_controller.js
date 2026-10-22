import { Controller } from "@hotwired/stimulus"

// A tick that shows or hides a panel, e.g. the box for a riff. The panel is
// found by its id plus "_panel"; it stays filled in while hidden, and the
// server drops what an unticked box holds. An empty tab box gets its strings
// and a first empty bar as soon as it shows, so typing can start at the fret.
export default class extends Controller {
  toggle(event) {
    const panel = document.getElementById(`${event.params.panel}_panel`)
    if (!panel) return

    panel.hidden = !event.target.checked
    if (panel.hidden) return

    const input = panel.querySelector("textarea")
    const addBar = panel.querySelector("[data-action~='tab#addBar']")
    if (input && addBar && input.value.trim() === "") addBar.click()
  }
}
