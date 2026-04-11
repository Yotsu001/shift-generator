function allPrimaryZoneOptions(primaryZoneSelect) {
  if (!primaryZoneSelect._allOptions) {
    primaryZoneSelect._allOptions = Array.from(primaryZoneSelect.options).map((option) => ({
      value: option.value,
      text: option.text,
      selected: option.selected,
    }))
  }

  return primaryZoneSelect._allOptions
}

function syncPrimaryZoneOptions(form) {
  const checkedZoneIds = Array.from(form.querySelectorAll('.employee-zone-checkbox:checked')).map((checkbox) => checkbox.value)
  const primaryZoneSelect = form.querySelector('.employee-primary-zone-select')

  if (!primaryZoneSelect) return

  const currentValue = primaryZoneSelect.value
  const options = allPrimaryZoneOptions(primaryZoneSelect)
  const visibleOptions = options.filter((option) => option.value === '' || checkedZoneIds.includes(option.value))

  primaryZoneSelect.innerHTML = ''

  visibleOptions.forEach((optionData) => {
    const option = document.createElement('option')
    option.value = optionData.value
    option.textContent = optionData.text
    primaryZoneSelect.appendChild(option)
  })

  if (currentValue !== '' && checkedZoneIds.includes(currentValue)) {
    primaryZoneSelect.value = currentValue
  } else {
    primaryZoneSelect.value = ''
  }
}

function setupEmployeeForms() {
  document.querySelectorAll('.employee-form').forEach((form) => {
    syncPrimaryZoneOptions(form)

    form.querySelectorAll('.employee-zone-checkbox').forEach((checkbox) => {
      checkbox.addEventListener('change', () => {
        syncPrimaryZoneOptions(form)
      })
    })
  })
}

window.addEventListener('turbo:load', setupEmployeeForms)
