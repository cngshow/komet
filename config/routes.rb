Rails.application.routes.draw do

  match 'logic_graph/chronology/:id' => 'logic_graph#chronology', :as => :logic_graph_chronology, via: [:get]
  match 'logic_graph/version/:id' => 'logic_graph#version', :as => :logic_graph_version, via: [:get]

  get 'komet_dashboard/dashboard'
  get 'komet_dashboard/metadata'
  get 'komet_dashboard/taxonomy/taxonomy' => 'taxonomy#taxonomy'
  get 'taxonomy/load_tree_data'
  get 'taxonomy/get_concept_information'
  get 'taxonomy/get_concept_summary'
  get 'taxonomy/get_concept_sememes'
  get 'taxonomy/get_concept_details'
  get 'taxonomy/get_concept_expression'
  get 'taxonomy/get_concept_refsets'
  get 'taxonomy/get_concept_references'
  get 'taxonomy/get_concept_members'
  #get 'taxonomy/test_ajax_js'
  #get 'taxonomy/test_render_partial'
  get 'taxonomy/render_concept_diagram'
  get 'taxonomy/svg_diagram'

  get 'search/get_assemblage_suggestions'
  get 'search/get_assemblage_recents'
  get 'search/get_search_results'
  post 'search/get_search_results'

  # You can have the root of your site routed with "root"
  root 'external#login'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

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
