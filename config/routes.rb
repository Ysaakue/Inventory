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
      post  '/identify_employee',                       to: 'employees#identify_employee'
      get   ':employee_id/counts',                      to: 'counts#index_by_employee'
    end
  end
  resources :users, except: [:new,:edit]
  get     '/counts',                                    to: 'counts#index'
  get     '/counts/:id/save_report',                    to: 'counts#report_save'
  get     '/counts/:id/pending_products/:employee_id',  to: 'counts#pending_products'
  get     '/counts/:id/download_report(.:format)',      to: 'counts#report_download'
  get     '/counts/:id/report_data',                    to: 'counts#report_data'
  get     '/counts/:id/products',                       to:'counts#products_simplified'
  post    '/counts/:id/question_results',               to: 'counts#question_results'
  post    '/counts/:id/fourth_count_release',           to: 'counts#fourth_count_release'
  post    '/counts/:id/ignore_product',                 to: 'counts#ignore_product'
  post    '/counts/:id/divide_products',                to: 'counts#divide_products'
  post    '/counts/:id/verify_count',                   to: 'counts#verify_count'
  post    '/counts/:id/set_nonconformity',              to: 'counts#set_nonconformity'
  put     '/submit_result',                             to: 'counts#submit_quantity_found'
  post    '/companies/:company_id/products/import',        to: 'imports#create'
  post    '/products/set_not_new',                      to: 'products#set_not_new'
end
