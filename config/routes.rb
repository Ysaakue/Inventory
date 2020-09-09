Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get "states/:state_id/cities", to: "cities#index"
  resources :clients, except: [:new,:edit] do 
    resources :products, except: [:new,:edit]
    resources :counts, except: [:index,:new,:edit]
    resources :imports, only: [:index,:show]
    get '/counts', to: 'counts#index_by_client'
  end
  resources :employees, except: [:new,:edit] do
    collection do
      post '/identify_employee', to: 'employees#identify_employee'
      get ':employee_id/counts', to: 'counts#index_by_employee'
    end
  end
  get '/counts', to: 'counts#index'
  get '/counts/:id/save_report', to: 'counts#report_save'
  get '/counts/:id/pending_products/:employee_id', to: 'counts#pending_products'
  get '/counts/:id/download_report(.:format)', to: 'counts#report_download'
  get '/counts/:id/report_data', to: 'counts#report_data'
  post '/counts/:id/question_results', to: 'counts#question_results'
  post '/counts/:id/fourth_count_release', to: 'counts#fourth_count_release'
  post '/counts/:id/ignore_product', to: 'counts#ignore_product'
  post '/counts/:id/divide_products', to: 'counts#divide_products'
  put '/submit_result', to: 'counts#submit_quantity_found'
  post '/clients/:client_id/products/import', to: 'imports#create'
  post '/products/set_not_new', to: 'products#set_not_new'
end
