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

    this.technicianNameTarget.innerText = intervals[0]

    this.blockStartTarget.innerText = "Begins: " + intervals[1]
    this.blockEndTarget.innerText = "Ends: " + intervals[2]
    
    if (technicianAvailable==="false") {
      this.technicianAvailableTarget.style.display = "none"
    } else {
      this.technicianAvailableTarget.style.display = ""
    }
  }

  hide() {
    this.popupTarget.style.display = "none"
  }
  
  create_workorder() {
    
    const availableWorkorderStart = document.getElementById("block_start")
    const availableWorkorderEnd = document.getElementById("block_end")
    const technicianName = document.getElementById("technician_name")

    const newWorkorderForm = document.getElementById("workorder_form")
    
    const workorderStart = document.getElementById("w_begin")
    workorderStart.value = availableWorkorderStart.innerText.split(" ")[1]
    
    const workorderEnd = document.getElementById("w_end")
    workorderEnd.value = availableWorkorderEnd.innerText.split(" ")[1]

    const assignedWorker = document.getElementById("name")
    assignedWorker.value = technicianName.innerText

    // Trigger the create_workorder event in index_controller.rb (there has to be a better way of doing this)
    newWorkorderForm.submit()
  }
}
