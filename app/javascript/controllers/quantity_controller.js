import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  increase() {
    const current = parseInt(this.inputTarget.value, 10) || 1
    const max = parseInt(this.inputTarget.max, 10) || 99

    this.inputTarget.value = Math.min(current + 1, max)
  }

  decrease() {
    const current = parseInt(this.inputTarget.value, 10) || 1

    this.inputTarget.value = Math.max(current - 1, 1)
  }

  validate() {
    let value = parseInt(this.inputTarget.value, 10)
    const max = parseInt(this.inputTarget.max, 10) || 99

    if (isNaN(value) || value < 1) value = 1
    if (value > max) value = max

    this.inputTarget.value = value
  }
}