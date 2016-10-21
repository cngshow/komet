Rails.application.routes.draw do

    match 'logic_graph/chronology/:id' => 'logic_graph#chronology', :as => :logic_graph_chronology, via: [:get]
    match 'logic_graph/version/:id' => 'logic_graph#version', :as => :logic_graph_version, via: [:get]

    post 'external/authenticate', as: :login
    get  'external/logout', :as => :logout

    get 'komet_dashboard/dashboard'
    get 'workflow/dashboard_workflow', :as => :workflow_dashboard
    get 'komet_dashboard/metadata'
    get 'komet_dashboard/version'
    get 'komet_dashboard/get_concept_suggestions'
    get 'komet_dashboard/get_concept_recents'
    get 'komet_dashboard/load_tree_data', :as => :taxonomy_load_tree_data
    get 'komet_dashboard/get_concept_information', :as => :taxonomy_get_concept_information
    get 'komet_dashboard/get_concept_summary', :as => :taxonomy_get_concept_summary
    get 'komet_dashboard/get_concept_sememes', :as => :taxonomy_get_concept_sememes
    get 'komet_dashboard/get_concept_refsets', :as => :taxonomy_get_concept_refsets
    get 'komet_dashboard/get_concept_children', :as => :taxonomy_get_concept_children
    get 'komet_dashboard/get_coordinates', :as => :taxonomy_get_coordinates
    get 'komet_dashboard/get_coordinatestoken', :as => :taxonomy_get_coordinatestoken
    get 'komet_dashboard/get_refset_list', :as => :taxonomy_get_refset_list
    get 'komet_dashboard/get_concept_create_info', :as => :taxonomy_get_concept_create_info
    get 'komet_dashboard/get_concept_edit_info', :as => :taxonomy_get_concept_edit_info
    post 'komet_dashboard/create_concept', :as => :taxonomy_create_concept
    post 'komet_dashboard/get_new_property_info', :as => :taxonomy_get_new_property_info
    post 'komet_dashboard/edit_concept', :as => :taxonomy_edit_concept
    get 'komet_dashboard/change_concept_state', :as => :taxonomy_change_concept_state
    get 'komet_dashboard/clone_concept', :as => :taxonomy_clone_concept
    post 'workflow/create_workflow', :as => :taxonomy_create_workflow
    get 'workflow/get_history', :as => :workflow_get_history
    get 'workflow/get_transition', :as => :workflow_get_transition
    get 'workflow/get_process', :as => :workflow_get_process
    get 'workflow/set_user_workflow', :as => :workflow_set_user_workflow
    get 'workflow/modal_transition_metadata', :as => :workflow_modal_transition_metadata
    get 'workflow/get_advanceable_process_information', :as => :workflow_get_advanceable_process_information
    post 'workflow/advance_workflow', :as => :workflow_advance_workflow

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
