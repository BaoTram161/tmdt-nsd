import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "eye", "eyeOff"]

  toggle() {
    const isPassword = this.inputTarget.type === "password"

    // Chuyển đổi giữa hiển thị và ẩn mật khẩu
    this.inputTarget.type = isPassword ? "text" : "password"

    // Thay đổi icon con mắt
    this.eyeTarget.classList.toggle("hidden", isPassword)
    this.eyeOffTarget.classList.toggle("hidden", !isPassword)
  }
}