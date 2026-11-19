import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["province", "commune"]

  connect() {
    this.filterCommunes()
  }

  filterCommunes() {
    const provinceName = this.provinceTarget.value
    const communeSelect = this.communeTarget

    Array.from(communeSelect.options).forEach((option, index) => {
      if (index === 0) return

      option.hidden = !provinceName ||
        option.dataset.provinceName !== provinceName
    })

    const selectedOption = communeSelect.selectedOptions[0]

    if (selectedOption && selectedOption.hidden) {
      communeSelect.value = ""
    }

    communeSelect.disabled = !provinceName
  }
}