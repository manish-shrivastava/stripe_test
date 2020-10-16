Rails.application.routes.draw do
  resources :users

  match 'pay', to: 'users#pay', via: [:get, :post]

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
