import { Controller } from "@hotwired/stimulus"

// A tick that shows or hides a panel, e.g. the box for a riff. The panel is
// found by its id plus "_panel"; it stays filled in while hidden, and the
// server drops what an unticked box holds.
export default class extends Controller {
  toggle(event) {
    const panel = document.getElementById(`${event.params.panel}_panel`)
    if (panel) panel.hidden = !event.target.checked
  }
}
