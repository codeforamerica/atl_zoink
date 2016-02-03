Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  root 'atlanta_endpoints#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  get 'data_sources' => 'atlanta_endpoints#index', :as => 'data_sources'
  get 'data_standards' => 'data_standards#index', :as => 'data_standards'

  get 'charts' => 'charts#index', :as => 'charts'
  get 'charts/top-violations' => 'charts#top_violations', :as => 'top_violations_chart'
  get 'charts/defendant-citation-distribution' => 'charts#defendant_citation_distribution', :as => 'defendant_citation_distribution_chart'

  namespace :api, defaults: {format: 'json'} do
    namespace :v0 do
      get 'top-violations' => 'api#top_violations'
      get 'defendant-citation-distribution' => 'api#defendant_citation_distribution'
    end
  end

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
