import { Controller } from "@hotwired/stimulus"

// Asks the surrounding Turbo frame again after a moment. The frame's new
// content brings the controller back only as long as there is more to wait for.
export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 2000 } }

  connect() {
    this.timer = setTimeout(() => this.reload(), this.intervalValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  reload() {
    const frame = this.element.closest("turbo-frame")
    if (frame.src === new URL(this.urlValue, location.href).href) frame.reload()
    else frame.src = this.urlValue
  }
}
