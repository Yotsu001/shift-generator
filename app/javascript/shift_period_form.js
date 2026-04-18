function setupShiftPeriodForms() {
  document.querySelectorAll('.js-date-input[data-disable-manual-entry="true"]').forEach((input) => {
    input.addEventListener('keydown', (event) => {
      if (event.key === 'Tab') return
      event.preventDefault()
    })

    input.addEventListener('paste', (event) => {
      event.preventDefault()
    })

    input.addEventListener('drop', (event) => {
      event.preventDefault()
    })

    input.addEventListener('focus', () => {
      if (typeof input.showPicker === 'function' && !input.disabled) {
        input.showPicker()
      }
    })
  })
}

window.addEventListener('turbo:load', setupShiftPeriodForms)
