function isInteractiveElement(target) {
  return Boolean(target.closest('a, button, input, select, textarea, summary, [data-turbo-method]'))
}

function visitRow(row) {
  const href = row.dataset.href

  if (!href) return

  window.location.href = href
}

function setupClickableTableRows() {
  document.querySelectorAll('.clickable-row[data-href]').forEach((row) => {
    if (row.dataset.rowLinkBound === 'true') return

    row.dataset.rowLinkBound = 'true'

    row.addEventListener('click', (event) => {
      if (isInteractiveElement(event.target)) return

      visitRow(row)
    })

    row.addEventListener('keydown', (event) => {
      if (event.key !== 'Enter' && event.key !== ' ') return
      if (isInteractiveElement(event.target)) return

      event.preventDefault()
      visitRow(row)
    })
  })
}

window.addEventListener('turbo:load', setupClickableTableRows)
