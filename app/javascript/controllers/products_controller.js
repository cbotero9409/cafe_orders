import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "filterInput", "tab"]
  static classes = ["active", "inactive"]

  connect() {
    this._timer = null
  }

  setFilter(event) {
    const filter = event.currentTarget.dataset.filter

    this.filterInputTarget.value = filter

    this.tabTargets.forEach(tab => {
      tab.classList.remove(...this.activeClasses, ...this.inactiveClasses)
      tab.classList.add(...(tab.dataset.filter === filter ? this.activeClasses : this.inactiveClasses))
    })

    this.formTarget.requestSubmit()
  }

  debounce() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this.formTarget.requestSubmit(), 300)
  }
}
