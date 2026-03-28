function setupToggleShiftCellForms() {
  const buttons = document.querySelectorAll(".toggle-button");

  buttons.forEach((button) => {
    button.addEventListener("click", () => {
      const targetId = button.dataset.target;
      const targetForm = document.getElementById(targetId);

      if (!targetForm) return;

      const cell = button.closest(".shift-cell");
      if (!cell) return;

      const formsInCell = cell.querySelectorAll(".toggle-form");
      formsInCell.forEach((form) => {
        if (form.id !== targetId) {
          form.classList.add("hidden");
        }
      });

      targetForm.classList.toggle("hidden");
    });
  });
}

window.addEventListener("turbo:load", setupToggleShiftCellForms);
window.addEventListener("turbo:render", setupToggleShiftCellForms);