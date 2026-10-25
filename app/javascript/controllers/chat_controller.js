import { Controller } from "@hotwired/stimulus"

// Keeps the newest message in view and sends on Enter; Shift+Enter is a
// new line.
export default class extends Controller {
  static targets = ["messages"]

  connect() {
    this.scroll()
    this.observer = new MutationObserver(() => this.scroll())
    this.observer.observe(this.messagesTarget, { childList: true })
  }

  disconnect() {
    this.observer.disconnect()
  }

  send(event) {
    if (event.key !== "Enter" || event.shiftKey || event.isComposing) return

    event.preventDefault()
    event.target.form.requestSubmit()
  }

  // The form stays put across refreshes, so it is emptied here rather than
  // replaced by the response.
  sent(event) {
    if (event.detail.success) event.target.reset()
  }

  scroll() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
