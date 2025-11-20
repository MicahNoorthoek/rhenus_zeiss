import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { target: String }

  connect() {
    console.log("[Autoclick] Connected. Looking for:", this.targetValue)

    const el = document.querySelector(this.targetValue)
    if (el) {
      el.click()
      console.log("[Autoclick] Clicked:", el)
    } else {
      console.warn("[Autoclick] No element found for selector:", this.targetValue)
    }

    // Prevent multiple runs
    this.element.remove()
  }
}
