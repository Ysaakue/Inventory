Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get "states/:state_id/cities", to: "cities#index"
  resources :clients, except: [:new,:edit] do 
    resources :products, except: [:new,:edit]
  end
  resources :employees, except: [:new,:edit] do
    collection do
      get '/identify_employee', to: 'employees#identify_employee'
    end
  end
    post '/clients/:client_id/products/import', to: 'products#import'
end
