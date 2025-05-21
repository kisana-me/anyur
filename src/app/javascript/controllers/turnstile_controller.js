import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    sitekey: String,
    environment: String
  }

  connect() {
    if (this.environmentValue === "development") {
      console.log("Turnstile: スキップ（開発環境）")
      return
    }
    if (window.turnstile) {
      this.renderWidget()
    } else {
      window.onloadTurnstileCallback = this.renderWidget.bind(this)
      this.loadScript()
    }
  }

  renderWidget() {
    turnstile.render(this.element, {
      sitekey: this.sitekeyValue
    })
  }

  loadScript() {
    const script = document.createElement("script")
    script.src = "https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onloadTurnstileCallback"
    script.async = true
    script.defer = true
    document.head.appendChild(script)
  }
}
