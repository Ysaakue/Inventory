Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth', controllers: {
    sessions: 'overrides/sessions',
    registrations: 'overrides/registrations'
  }
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  
  get "dashboard", to: "application#dashboard"
  get "states/:state_id/cities", to: "cities#index"
  
  resources :companies, except: [:new,:edit] do 
    resources :products, except: [:new,:edit]
    resources :counts, except: [:index,:new,:edit]
    resources :imports, only: [:index,:show]
    get '/counts', to: 'counts#index_by_company'
  end
  resources :employees, except: [:new,:edit] do
    collection do
      post 'identify_employee',   to: 'employees#identify_employee'
      get  ':employee_id/counts', to: 'counts#index_by_employee'
    end
  end
  resources :users, except: [:new,:edit]
  resources :counts, only: [:index] do
    collection do
      get  'merge_reports'
      get  ':id/count_dashboard',               to: 'counts#dashboard'
      get  ':id/count_dashboard_table',         to: 'counts#dashboard_table'
      get  ':id/save_report',                   to: 'counts#report_save'
      get  ':id/pending_products/:employee_id', to: 'counts#pending_products'
      get  ':id/download_report(.:format)',     to: 'counts#report_download'
      get  ':id/report_data',                   to: 'counts#report_data'
      get  ':id/products',                      to:'counts#products_simplified'
      post ':id/question_results',              to: 'counts#question_results'
      post ':id/fourth_count_release',          to: 'counts#fourth_count_release'
      post ':id/ignore_product',                to: 'counts#ignore_product'
      post ':id/divide_products',               to: 'counts#divide_products'
      post ':id/verify_count',                  to: 'counts#verify_count'
      post ':id/set_nonconformity',             to: 'counts#set_nonconformity'
    end
  end
  resources :products, only: [] do
    collection do
      post 'set_not_new', to: 'products#set_not_new'
      post ':id/remove_location', to: 'products#remove_location'
    end
  end
  resources :roles, only: [:index,:create]
  put  '/submit_result',                         to: 'counts#submit_quantity_found'
  post '/companies/:company_id/products/import', to: 'imports#create'
end
