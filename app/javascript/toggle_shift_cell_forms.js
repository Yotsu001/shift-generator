function handleToggleShiftCellFormClick(event) {
  const button = event.target.closest('.toggle-button')
  if (!button) return

  const targetId = button.dataset.target
  if (!targetId) return

  const targetForm = document.getElementById(targetId)
  if (!targetForm) return

  const cell = button.closest('.shift-cell')
  if (!cell) return

  const formsInCell = cell.querySelectorAll('.toggle-form')
  formsInCell.forEach((form) => {
    if (form.id !== targetId) {
      form.classList.add('hidden')
    }
  })

  targetForm.classList.toggle('hidden')
}

function setupToggleShiftCellForms() {
  document.removeEventListener('click', handleToggleShiftCellFormClick)
  document.addEventListener('click', handleToggleShiftCellFormClick)
}

window.addEventListener('turbo:load', setupToggleShiftCellForms)
