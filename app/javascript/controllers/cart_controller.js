import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity", "input"]
  static values = { max: Number }

  connect() {
    this._qty = 1
  }

  increment() {
    if (this._qty < this.maxValue) {
      this._qty++
      this._sync()
    }
  }

  decrement() {
    if (this._qty > 1) {
      this._qty--
      this._sync()
    }
  }

  _sync() {
    this.quantityTarget.textContent = this._qty
    this.inputTarget.value = this._qty
  }
}
