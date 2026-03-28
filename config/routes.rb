Rails.application.routes.draw do
  devise_for :users
  root "homes#index"

  resources :shift_periods, only: [:index, :new, :create, :show]
  
  resources :shift_days, only: [] do
    resources :shift_assignments, only: [:create, :edit, :update, :destroy]
    resources :leave_requests, only: [:create, :edit, :update, :destroy]
  end
end