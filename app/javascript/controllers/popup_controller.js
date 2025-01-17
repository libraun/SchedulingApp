import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="popup"
export default class extends Controller {

  static targets = [
    "popup", "grid",
    "blockStart", "blockEnd",
    "technicianName", "technicianAvailable"
  ]

  show() {
    this.popupTarget.style.display = "flex"

    let intervals = event.target.value.split("=")

    let technicianAvailable = intervals[3]

    this.technicianNameTarget.value = intervals[0]

    this.blockStartTarget.value = intervals[1]
    this.blockEndTarget.value = intervals[2]
    
    if (technicianAvailable==="false") {
      this.technicianAvailableTarget.style.display = "none"
    } else {
      this.technicianAvailableTarget.style.display = ""
    }
  }

  hide() {
    this.popupTarget.style.display = "none"
  }
}
