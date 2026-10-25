import { Controller } from "@hotwired/stimulus"

// Songs or text in the left sidebar. The tab chosen last is remembered in a
// cookie, like the sidebars themselves.
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.select(this.element.dataset.sidebarTabValue)
  }

  show(event) {
    const name = event.currentTarget.dataset.tab
    this.select(name)
    document.cookie = `sidebar_tab=${name}; path=/; max-age=31536000; samesite=lax`
  }

  select(name) {
    this.tabTargets.forEach((tab) => tab.setAttribute("aria-selected", tab.dataset.tab === name))
    this.panelTargets.forEach((panel) => { panel.hidden = panel.dataset.tab !== name })
  }
}
