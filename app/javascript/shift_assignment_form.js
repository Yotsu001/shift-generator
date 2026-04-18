function updateZoneField(workTypeSelect, zoneField, zoneSelect) {
  const value = workTypeSelect.value;

  if (value === "day_shift" || value === "middle_shift" || value === "night_shift") {
    zoneField.style.display = "block";
  } else {
    zoneField.style.display = "none";
    zoneSelect.value = "";
  }
}

function setupShiftAssignmentForms() {
  const forms = document.querySelectorAll(".shift-assignment-form");

  forms.forEach((form) => {
    const workTypeSelect = form.querySelector(".work-type-select");
    const zoneField = form.querySelector(".zone-field");
    const zoneSelect = form.querySelector(".zone-select");

    if (!workTypeSelect || !zoneField || !zoneSelect) return;

    updateZoneField(workTypeSelect, zoneField, zoneSelect);

    workTypeSelect.addEventListener("change", () => {
      updateZoneField(workTypeSelect, zoneField, zoneSelect);
    });
  });
}

window.addEventListener("turbo:load", setupShiftAssignmentForms);
window.addEventListener("turbo:render", setupShiftAssignmentForms);
