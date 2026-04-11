Rails.application.routes.draw do
  devise_for :users
  root "homes#index"

  resources :employees
  resources :zones, only: %i[index new create edit update]

  resources :shift_periods do
    member do
      post :generate
      delete :clear_assignments
    end
  end
  
  resources :shift_days, only: [] do
    resources :shift_assignments, only: [:create, :edit, :update, :destroy]
    resources :leave_requests, only: [:create, :edit, :update, :destroy]
  end

end
