# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "shift_assignment_form", to: "shift_assignment_form.js"
pin "toggle_shift_cell_forms", to: "toggle_shift_cell_forms.js"
pin "employee_form", to: "employee_form.js"
pin "shift_period_form", to: "shift_period_form.js"
