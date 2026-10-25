import { Controller } from "@hotwired/stimulus"

// The form as keys: dragged into order, × removes one, the palette adds a
// section at the end. Every change writes the names, comma separated, into
// the hidden field the server reads. The palette follows the section names
// below, and renaming a section renames its keys.
export default class extends Controller {
  static targets = ["input", "list", "item", "label", "template", "palette", "section", "empty"]

  pick(event) {
    this.dragged = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.dragged.dataset.name)
    requestAnimationFrame(() => this.dragged?.classList.add("is-dragging"))
  }

  // The key moves while it is dragged, so the row shows where it will land.
  over(event) {
    if (!this.dragged) return

    event.preventDefault()
    const target = event.target.closest("[data-form-order-target='item']")
    if (!target || target === this.dragged) return

    const box = target.getBoundingClientRect()
    const after = event.clientX > box.left + box.width / 2
    target.parentNode.insertBefore(this.dragged, after ? target.nextSibling : target)
  }

  dropped(event) {
    event.preventDefault()
  }

  drop() {
    this.dragged?.classList.remove("is-dragging")
    this.dragged = null
    this.write()
  }

  remove(event) {
    event.currentTarget.closest("[data-form-order-target='item']").remove()
    this.write()
  }

  add(event) {
    this.listTarget.append(this.key(event.currentTarget.dataset.name))
    this.write()
  }

  remember(event) {
    event.target.dataset.previous = event.target.value.trim()
  }

  renamed(event) {
    const before = event.target.dataset.previous
    const after = event.target.value.trim()
    if (before && after && before !== after) {
      this.itemTargets.filter((item) => item.dataset.name === before).forEach((item) => this.rename(item, after))
      this.write()
    }
    event.target.dataset.previous = after
  }

  // The palette: one button per named section, in the order they stand.
  sections() {
    const names = [...new Set(this.sectionTargets.map((input) => input.value.trim()).filter(Boolean))]
    const label = this.paletteTarget.querySelector(".eyebrow")
    this.paletteTarget.replaceChildren(label, ...names.map((name) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "ring-button !px-3 !py-1 !text-base"
      button.dataset.action = "form-order#add"
      button.dataset.name = name
      button.textContent = `+ ${name}`
      return button
    }))
  }

  key(name) {
    const item = this.templateTarget.content.firstElementChild.cloneNode(true)
    this.rename(item, name)
    return item
  }

  rename(item, name) {
    item.dataset.name = name
    item.querySelector("[data-form-order-target='label']").textContent = name
    item.querySelector("button").setAttribute("aria-label", `${name} entfernen`)
  }

  write() {
    this.inputTarget.value = this.itemTargets.map((item) => item.dataset.name).join(", ")
    this.emptyTarget.hidden = this.itemTargets.length > 0
  }
}
