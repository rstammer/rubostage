import { Controller } from "@hotwired/stimulus"

// Draws the left and right sidebar in and out. The state goes into a cookie,
// so the server draws the next page the same way and nothing jumps. The
// header's height is handed to CSS, which hangs the sidebars below it.
export default class extends Controller {
  static targets = ["left", "right"]

  connect() {
    this.header = document.querySelector("body > header")
    this.measure = () => this.element.style.setProperty("--header-h", `${this.header.offsetHeight}px`)
    this.measure()
    this.observer = new ResizeObserver(this.measure)
    this.observer.observe(this.header)
    // Without a choice yet, a narrow screen starts with both drawn in, as
    // an open one would lie over the page.
    if (window.matchMedia("(width < 64rem)").matches) {
      for (const side of ["left", "right"]) {
        if (!document.cookie.includes(`sidebar_${side}=`)) this.targetFor(side).dataset.state = "closed"
      }
    }
  }

  targetFor(side) {
    return side === "left" ? this.leftTarget : this.rightTarget
  }

  disconnect() {
    this.observer.disconnect()
  }

  toggle(event) {
    const side = event.currentTarget.dataset.side
    const sidebar = this.targetFor(side)
    const state = sidebar.dataset.state === "open" ? "closed" : "open"
    sidebar.dataset.state = state
    event.currentTarget.setAttribute("aria-expanded", state === "open")
    document.cookie = `sidebar_${side}=${state}; path=/; max-age=31536000; samesite=lax`
  }
}
