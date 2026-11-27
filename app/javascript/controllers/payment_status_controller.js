import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "countdown",
    "paymentContent",
    "expiredPanel",
    "paidPanel",
    "status"
  ]

  static values = {
    url: String,
    expiresAt: String
  }

  connect() {
    this.poll()
    this.pollTimer = setInterval(() => this.poll(), 5000)
    this.clockTimer = setInterval(() => this.updateCountdown(), 1000)

    this.updateCountdown()
  }

  disconnect() {
    clearInterval(this.pollTimer)
    clearInterval(this.clockTimer)
  }

  async poll() {
    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "application/json" },
        credentials: "same-origin"
      })

      if (!response.ok) return

      const data = await response.json()

      if (data.paid) {
        this.showPaid()
        return
      }

      if (data.expired) {
        this.showExpired()
      }
    } catch (error) {
      console.error("Không thể kiểm tra trạng thái thanh toán:", error)
    }
  }

  updateCountdown() {
    if (!this.hasCountdownTarget || !this.expiresAtValue) return

    const remaining = Math.max(
      0,
      Math.floor((Date.parse(this.expiresAtValue) - Date.now()) / 1000)
    )

    const minutes = String(Math.floor(remaining / 60)).padStart(2, "0")
    const seconds = String(remaining % 60).padStart(2, "0")

    this.countdownTarget.textContent = `${minutes}:${seconds}`

    if (remaining === 0) {
      this.showExpired()
    }
  }

  showExpired() {
    if (this.hasPaymentContentTarget) {
      this.paymentContentTarget.hidden = true
    }

    if (this.hasExpiredPanelTarget) {
      this.expiredPanelTarget.hidden = false
    }

    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "PHIÊN THANH TOÁN ĐÃ HẾT HẠN"
    }
  }

  showPaid() {
    clearInterval(this.pollTimer)
    clearInterval(this.clockTimer)

    if (this.hasPaymentContentTarget) {
      this.paymentContentTarget.hidden = true
    }

    if (this.hasExpiredPanelTarget) {
      this.expiredPanelTarget.hidden = true
    }

    if (this.hasPaidPanelTarget) {
      this.paidPanelTarget.hidden = false
    }

    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "THANH TOÁN THÀNH CÔNG"
    }
  }
}
