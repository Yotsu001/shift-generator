Rails.application.routes.draw do
  devise_for :users
  root "homes#index"

  resources :shift_periods, only: [:index, :new, :create, :show] do
end
end