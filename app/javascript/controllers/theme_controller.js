import { Controller } from "@hotwired/stimulus"

// Light/dark switch. The choice is remembered per browser; without storage the
// page simply follows the system setting.
export default class extends Controller {
  connect() {
    try {
      const saved = localStorage.getItem("theme")
      if (saved) document.documentElement.dataset.theme = saved
    } catch (_) {}
  }

  toggle() {
    const root = document.documentElement
    const dark = root.dataset.theme
      ? root.dataset.theme === "dark"
      : window.matchMedia("(prefers-color-scheme: dark)").matches
    root.dataset.theme = dark ? "light" : "dark"
    try { localStorage.setItem("theme", root.dataset.theme) } catch (_) {}
  }
}
