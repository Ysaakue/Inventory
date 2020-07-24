Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get "states/:state_id/cities", to: "cities#index"
  resources :clients, except: [:new,:edit] do 
    resources :products, except: [:new,:edit]
    resources :counts, except: [:index,:new,:edit] do
    end
    get '/counts', to: 'counts#index_by_client'
  end
  resources :employees, except: [:new,:edit] do
    collection do
      post '/identify_employee', to: 'employees#identify_employee'
      get ':employee_id/counts', to: 'counts#index_by_employee'
    end
  end
  post '/counts/:id/fourth_count_release', to: 'counts#fourth_count_release'
  post '/clients/:client_id/products/import', to: 'products#import'
  put '/submit_result', to: 'counts#submit_quantity_found'
  get '/counts', to: 'counts#index'
  get '/counts/:id/report', to: 'counts#report'
end
