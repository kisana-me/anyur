import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "dots"]
  static values = {
    index: Number
  }

  connect() {
    this.indexValue = 0
    this.total = this.trackTarget.children.length
    this.startAutoRotate()
  }

  prev() {
    this.indexValue = (this.indexValue === 0) ? this.total - 1 : this.indexValue - 1
    this.update()
  }

  next() {
    this.indexValue = (this.indexValue + 1) % this.total
    this.update()
  }

  goTo(event) {
    const newIndex = parseInt(event.currentTarget.dataset.carouselIndexValue, 10)
    this.indexValue = newIndex
    this.update()
  }

  update() {
    this.trackTarget.style.transform = `translateX(-${this.indexValue * 100}%)`

    const dots = this.dotsTarget.querySelectorAll('.dot')
    dots.forEach((dot, i) => {
      dot.classList.toggle("active", i === this.indexValue)
    })
  }

  startAutoRotate() {
    this.interval = setInterval(() => {
      this.next();
    }, 8000)
  }

  disconnect() {
    clearInterval(this.interval)
  }
}
