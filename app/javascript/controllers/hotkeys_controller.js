import { Controller } from "@hotwired/stimulus"

// Keys for the hands that are on the guitar: every button with a
// data-hotkey is pressed by that key, unless someone is typing.
export default class extends Controller {
  connect() {
    this.press = this.press.bind(this)
    document.addEventListener("keydown", this.press)
  }

  disconnect() {
    document.removeEventListener("keydown", this.press)
  }

  press(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return
    if (event.target.closest("input, textarea, select")) return

    const key = event.key === " " ? "space" : event.key.toLowerCase()
    const button = this.element.querySelector(`[data-hotkey~="${key}"]`)
    if (!button) return

    event.preventDefault()
    button.click()
  }
}
