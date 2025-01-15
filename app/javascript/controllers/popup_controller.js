import { Controller } from "@hotwired/stimulus"
import { application } from "./application"

// Connects to data-controller="popup"
export default class extends Controller {
  static targets = [
    "popup", "grid",
    "blockStart", "blockEnd"
  ]

  show() {
    this.popupTarget.style.display = "flex"

    // Intervals: 
    let intervals = event.target.value.split(" ")

    console.assert(intervals.length === 2)

    this.blockStartTarget.innerText = "Begins: " + intervals[0]
    this.blockEndTarget.innerText = "Ends: " + intervals[1]
  }

  hide() {
    this.popupTarget.style.display = "none"
  }

  create_workorder() {

    const availableWorkorderStart = document.getElementById("block_start");
    const availableWorkorderEnd = document.getElementById("block_end");

    const newWorkorderForm = document.getElementById("workorder_form");
    
    const workorderStart = document.getElementById("w_begin");
    workorderStart.value = availableWorkorderStart.innerText.split(" ")[1];
    
    const workorderEnd = document.getElementById("w_end");
    workorderEnd.value = availableWorkorderEnd.innerText.split(" ")[1];

    const assignedWorker = document.getElementById("name");
    assignedWorker.value = "Bill Keller";

    console.log(workorderStart.value, workorderEnd.value,)

    newWorkorderForm.submit()
  }
}
