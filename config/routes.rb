Rails.application.routes.draw do

  match 'logic_graph/chronology/:id' => 'logic_graph#chronology', :as => :logic_graph_chronology, via: [:get]
  match 'logic_graph/version/:id' => 'logic_graph#version', :as => :logic_graph_version, via: [:get]

  post 'external/authenticate', as: :login
  get  'external/logout', :as => :logout

  get 'komet_dashboard/dashboard'
  get 'komet_dashboard/metadata'
  get 'komet_dashboard/version'
  get 'komet_dashboard/get_concept_suggestions'
  get 'komet_dashboard/get_concept_recents'
  get 'komet_dashboard/load_tree_data', :as => :taxonomy_load_tree_data
  get 'komet_dashboard/get_concept_information', :as => :taxonomy_get_concept_information
  get 'komet_dashboard/get_concept_summary', :as => :taxonomy_get_concept_summary
  get 'komet_dashboard/get_concept_sememes', :as => :taxonomy_get_concept_sememes
  get 'komet_dashboard/get_concept_refsets', :as => :taxonomy_get_concept_refsets
  get 'komet_dashboard/get_concept_languages_dialect', :as => :taxonomy_get_concept_languages_dialect
  get 'komet_dashboard/get_coordinates', :as => :taxonomy_get_coordinates
  get 'komet_dashboard/get_coordinatestoken', :as => :taxonomy_get_coordinatestoken
  get 'komet_dashboard/get_refset_list', :as => :taxonomy_get_refset_list
  get 'komet_dashboard/get_concept_add', :as => :taxonomy_get_concept_add
  get 'komet_dashboard/get_concept_edit', :as => :taxonomy_get_concept_edit
  get 'komet_dashboard/get_attributes_jsonreturntype', :as => :taxonomy_get_attributes_jsonreturntype
  get 'komet_dashboard/get_descriptions_jsonreturntype', :as => :taxonomy_get_descriptions_jsonreturntype

  get 'search/get_assemblage_suggestions'
  get 'search/get_assemblage_recents'
  get 'search/get_search_results'
  post 'search/get_search_results'

  get 'komet_dashboard/mapping/mapping'
  get 'mapping/load_tree_data'
  get 'mapping/load_mapping_viewer'
  get 'mapping/get_overview_sets_results'
  get 'mapping/get_overview_items_results'
  get 'mapping/map_set_editor'
  post 'mapping/process_map_set'
  get 'mapping/map_item_editor'
  post 'mapping/process_map_item'
  get 'mapping/get_item_source_suggestions'
  get 'mapping/get_item_source_recents'
  get 'mapping/get_item_target_suggestions'
  get 'mapping/get_item_target_recents'
  get 'mapping/get_item_kind_of_suggestions'
  get 'mapping/get_item_kind_of_recents'
  get 'mapping/get_target_candidates_results'

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
