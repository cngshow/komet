=begin
Copyright Notice

 This is a work of the U.S. Government and is not subject to copyright
 protection in the United States. Foreign copyrights may apply.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
=end

require './lib/isaac_rest/taxonomy_rest'
require './lib/rails_common/util/controller_helpers'

##
# KometDashboardController -
# handles the loading of the taxonomy tree
class KometDashboardController < ApplicationController
  include TaxonomyConcern, ConceptConcern, InstrumentationConcern
  include CommonController

  before_action :setup_routes, :setup_constants, :only => [:dashboard]
  after_filter :byte_size unless Rails.env.production?

  ##
  # load_tree_data - RESTful route for populating the taxonomy tree using an http :GET
  # The current tree node is identified in the request params with the key :concept_id
  # If the tree is reversed so we are searching for parents of this node is identified in the request params with the key :parent_search (true/false)
  # If the parent of this node was already doing a reverse search is identified in the request params with the key :parent_reversed (true/false)
  # Whether to display the stated (true) or inferred view of concepts with a request param of :stated (true/false)
  #@return [json] the tree nodes to insert into the tree at the parent node passed in the request
  def load_tree_data
#    roles = session[Roles::SESSION_USER_ROLES]
#    if(roles.include?(Roles::DEV_SUPER_USER))
#      #do something
#    end

    selected_concept_id = params[:concept_id]
    parent_search = params[:parent_search]
    parent_reversed = params[:parent_reversed]
    stated = params[:stated]
    tree_walk_levels = params[:tree_walk_levels]
    multi_path = params[:multi_path]

    # check to make sure the flag for stated or inferred view was passed in
    if stated != nil
      @stated = stated
    end

    # check to make the number of levels to walk the tree was passed in
    if tree_walk_levels == nil
      tree_walk_levels = 1
    else
      tree_walk_levels = tree_walk_levels.to_i
    end

    # check to make sure the flag for exploring multiple parent paths was passed in
    if multi_path == nil
      multi_path = true
    end

    tree_nodes = populate_tree(selected_concept_id, parent_search, parent_reversed, tree_walk_levels, multi_path)

    render json: tree_nodes
  end

  ##
  # get_concept_information - RESTful route for populating concept details pane using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # Whether to display the stated (true) or inferred view of concepts with a request param of :stated (true/false)
  # The javascript partial to render is identified in the request params with the key :partial
  # @return [javascript] render a javascript partial that re-renders all needed partials
  def get_concept_information

    @concept_id = params[:concept_id]
    @stated = params[:stated]
    @viewer_id =  params[:viewer_id]

    if @viewer_id == nil || @viewer_id == '' || @viewer_id == 'new'
      @viewer_id = get_next_id
    end

    get_concept_attributes(@concept_id, @stated)
    get_concept_descriptions(@concept_id, @stated)
    get_concept_sememes(@concept_id, @stated)
    render partial: params[:partial]

  end

  def get_concept_add_edit

    @concept_id = params[:concept_id]
    @stated = params[:stated]
    @viewer_id =  params[:viewer_id]

    if @viewer_id == nil || @viewer_id == '' || @viewer_id == 'new'
      @viewer_id = get_next_id
    end


    render partial: params[:partial]

  end

  ##
  # get_concept_attributes - RESTful route for populating concept attribute tab using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the @attributes variable
  def get_concept_attributes(concept_id = nil, stated = nil)

    if concept_id == nil && params[:concept_id]
      concept_id = params[:concept_id].to_i
    end

    if stated == nil && params[:stated]
      stated = params[:stated]
    end

    @attributes =  get_attributes(concept_id, stated)

  end

  ##
  # get_concept_descriptions - RESTful route for populating concept summary tab using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the @descriptions variable
  def get_concept_descriptions(concept_id = nil, stated = nil)

    if concept_id == nil && params[:concept_id]
      concept_id = params[:concept_id].to_i
    end

    if stated == nil && params[:stated]
      stated = params[:stated]
    end

    @descriptions =  get_descriptions(concept_id, stated)

  end

  ##
  # get_concept_sememes - RESTful route for populating concept sememes section using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the @concept_sememes variable
  def get_concept_sememes(concept_id = nil, stated = nil)

    if concept_id == nil && params[:concept_id]
      concept_id = params[:concept_id].to_i
    end

    if stated == nil && params[:stated]
      stated = params[:stated]
    end

    @concept_sememes = get_attached_sememes(concept_id, stated) # descriptions(concept_id)

  end

  def get_concept_languages_dialect()
    uuid = params[:uuid]
    languages = get_languages_dialect(uuid)
    render json: languages
  end

  # gets default/ users preference coordinates
  def get_coordinates
    getcoordinates_results = {}
    token = session[:coordinatestoken].token
    additional_req_params = {coordToken: token}
    $log.debug("token get_coordinates #{token}" )
    getcoordinates_results = CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES,additional_req_params: additional_req_params)
    value = getcoordinates_results.languageCoordinate.to_json
    getcoordinates_results = JSON.parse(getcoordinates_results.to_json)
    getcoordinates_results[:colormodule]= session[:colormodule]
    getcoordinates_results[:colorpath]= session[:colorpath]
    getcoordinates_results[:colorrefsets]= session[:colorrefsets]
    render json:  getcoordinates_results.to_json
  end

  def get_coordinatestoken
  hash = { }
  hash[:language] = params[:language]
  hash[:dialectPrefs] = params[:dialectPrefs]
  hash[:descriptionTypePrefs] = params[:descriptionTypePrefs]
  hash[:allowedStates]= params[:allowedStates]
  session[:colormodule] =params[:colormodule]
  session[:colorpath] =params[:colorpath]
  session[:colorrefsets] =params[:colorrefsets]
  results =  CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES_TOKEN,  additional_req_params: hash)
  session[:coordinatestoken] = results
 $log.debug("token get_coordinatestoken #{results.token}" )
  render json:  results.to_json

  end

  def get_refset_list

    coordinates_token = session[:coordinatestoken].token
    stated = params[:stated]

    # check to make sure the flag for stated or inferred view was passed in
    if stated != nil
      @stated = stated
    end

    additional_req_params = {coordToken: coordinates_token, stated: @stated, childDepth: 50}

    refsets = TaxonomyRest.get_isaac_concept(uuid: $PROPS['KOMET.assemblage_concept_id'], additional_req_params: additional_req_params)

    if refsets.is_a? CommonRest::UnexpectedResponse
      render json: [] and return
    end

    processed_refsets = process_refset_list(refsets)

    render json: processed_refsets.to_json

  end

  def process_refset_list(concept)

    refset_nodes = {}

    node = {}
    node[concept.conChronology.conceptSequence] = concept.conChronology.description
    has_children = !concept.children.nil?

    # get the children
    if has_children
      children = concept.children
    else

      children = []
      refset_nodes.merge!(node)
    end

    children.each do |child|
      refset_nodes.merge!(process_refset_list(child))
    end

    refset_nodes
  end

  ##
  # get_concept_refsets - RESTful route for populating concept refsets section using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the refsets variable
  def get_concept_refsets()
    concept_id = params[:concept_id]
    stated = params[:stated]
    refsets = get_refsets(concept_id, stated) # descriptions(concept_id)
    render json: refsets
  end

  def populate_tree(selected_concept_id, parent_search, parent_reversed, tree_walk_levels, multi_path)

    coordinates_token = session[:coordinatestoken].token
    root = selected_concept_id.eql?('#')

    additional_req_params = {coordToken: coordinates_token, stated: @stated, sememeMembership: true}

    if boolean(parent_search)
      tree_walk_levels = 100
      additional_req_params[:childDepth] = 0
      additional_req_params[:parentHeight] = tree_walk_levels
    else

      additional_req_params[:childDepth] = tree_walk_levels
      additional_req_params[:parentHeight] = 1
    end

    if root

      # load the ISAAC root node and children
      isaac_concept = TaxonomyRest.get_isaac_root(additional_req_params: additional_req_params)

      # load the root node into our return variable
      root_anchor_attributes = { class: 'komet-context-menu', 'data-menu-type' => 'concept', 'data-menu-uuid' => isaac_concept.conChronology.identifiers.uuids.first}
      root_node = {id: 0, concept_id: isaac_concept.conChronology.identifiers.uuids.first, text: isaac_concept.conChronology.description, parent_reversed: false, parent_search: parent_search, icon: 'komet-tree-node-icon komet-tree-node-primitive', a_attr: root_anchor_attributes, state: {opened: 'true'}}
    else
      isaac_concept = TaxonomyRest.get_isaac_concept(uuid: selected_concept_id, additional_req_params: additional_req_params)
    end

    if isaac_concept.is_a? CommonRest::UnexpectedResponse
      render json: [] and return
    end

    raw_nodes = process_rest_concept(isaac_concept, tree_walk_levels, first_level: true, parent_search: parent_search, multi_path: multi_path)
    processed_nodes = process_tree_level(raw_nodes, [], parent_search, parent_reversed)

    if root

      root_node[:children] = processed_nodes
      return [root_node]
    else
      return processed_nodes
    end
  end

  def process_rest_concept(concept, tree_walk_levels, first_level: false, parent_search: false, multi_path: true)

    concept_nodes = []
    has_many_parents = false

    node = {}
    node[:id] = concept.conChronology.identifiers.uuids.first
    node[:text] = concept.conChronology.description
    node[:has_children] = !concept.children.nil?
    node[:defined] = concept.isConceptDefined
    node[:state] = concept.conVersion.state
    node[:author] = concept.conVersion.authorSequence
    node[:module] = concept.conVersion.moduleSequence
    node[:path] = concept.conVersion.pathSequence
    node[:refsets] = concept.sememeMembership

    if node[:defined].nil?
      node[:defined] = false
    end

    if node[:has_children]
      node[:child_count] = concept.children.length

    elsif tree_walk_levels == 0 && concept.childCount != 0

      node[:child_count] = concept.childCount
      node[:has_children] = true
      node[:has_children] = true

    else
      node[:child_count] = 0
    end

    node[:has_parents] = !concept.parents.nil?

    if node[:has_parents]
      node[:parent_count] = concept.parents.length

    elsif tree_walk_levels == 0 && concept.parentCount != 0 && boolean(parent_search)

      node[:parent_count] = concept.parentCount
      node[:has_parents] = true

    else
      node[:parent_count] = 0
    end

    if !boolean(parent_search) && node[:child_count] != 0
      node[:badge] = "&nbsp;&nbsp;<span class=\"badge badge-success\" title=\"kma\">#{node[:child_count]}</span>"

    elsif boolean(parent_search) && node[:parent_count] != 0
      node[:badge] = "&nbsp;&nbsp;<span class=\"badge badge-success\" title=\"kma\">#{node[:parent_count]}</span>"
    else
      node[:badge] = ''
    end

    node[:parents] = []

    # if this node has parents and we want to see all parent paths then get the details of each parent
    if tree_walk_levels > 0  && !boolean(parent_search) && node[:parent_count] > 1 && boolean(multi_path)

      has_many_parents = true

      if first_level
        node[:badge] = "&nbsp;&nbsp;<span class=\"badge badge-success\" title=\"kma\">#{node[:parent_count]}</span>"
      end

      concept.parents.each do |parent|

        parent_node = {}

        parent_node[:id] = parent.conChronology.identifiers.uuids.first
        parent_node[:text] = parent.conChronology.description
        parent_node[:defined] = parent.isConceptDefined
        parent_node[:state] = parent.conVersion.state
        parent_node[:author] = parent.conVersion.authorSequence
        parent_node[:module] = parent.conVersion.moduleSequence
        parent_node[:path] = parent.conVersion.pathSequence
        parent_node[:has_parents] = parent.parentCount.to_i > 0
        parent_node[:parent_count] = parent.parentCount

        if node[:parent_count] != 0
          parent_node[:badge] = "&nbsp;&nbsp;<span class=\"badge badge-success\" title=\"kma\">#{parent_node[:parent_count]}</span>"
        end

        if parent_node[:defined].nil?
          parent_node[:defined] = false
        end
        
        node[:parents] << parent_node
      end
    end

    relation = :children

    # if we are walking up the tree toward the root node get the parents of the current node, otherwise get the children
    if tree_walk_levels > 0 && boolean(parent_search) && !concept.parents.nil?

      relation = :parents
      related_concepts = concept.parents

    elsif tree_walk_levels > 0 && !boolean(parent_search) && !concept.children.nil?
      related_concepts = concept.children
    else
      related_concepts = []
    end

    processed_related_concepts = []

    related_concepts.each do |related_concept|
      processed_related_concepts.concat(process_rest_concept(related_concept, tree_walk_levels - 1, parent_search: parent_search, multi_path: multi_path))
    end

    if first_level

      if has_many_parents
        concept_nodes << node
      end

      concept_nodes.concat(processed_related_concepts)
    else
      $log.debug('*** data process: ' + node[:text])
      node[relation] = processed_related_concepts
      concept_nodes << node
    end

    concept_nodes
  end

  def process_tree_level (raw_nodes, tree_nodes, parent_search_param, parent_reversed_param)

    raw_nodes.each do |raw_node|

      anchor_attributes = { class: 'komet-context-menu', 'data-menu-type' => 'concept', 'data-menu-uuid' => raw_node[:id]}
      parent_search = parent_search_param
      parent_reversed = parent_reversed_param
      show_expander = true
      relation = :children
      has_relation = :has_children
      flags = get_tree_node_flag('module', [raw_node[:module]])
      flags << get_tree_node_flag('refsets', [raw_node[:refsets]])
      flags << get_tree_node_flag('path', [raw_node[:path]])

      if boolean(parent_search)

        relation = :parents
        has_relation = :has_parents
      end

      if boolean(raw_node[:defined])
        icon_class = 'komet-tree-node-icon komet-tree-node-defined'
      else
        icon_class = 'komet-tree-node-icon komet-tree-node-primitive'
      end

      # should this child node be reversed and is it the first node to be reversed - comes from node data
      if !boolean(parent_reversed) && raw_node[:parent_count] > 1

        anchor_attributes[:class] << ' komet-reverse-tree-node'
        parent_id = get_next_id
        node_text = 'Parents of ' + raw_node[:text] + raw_node[:badge] + flags
        icon_class << '-arrow'

        parent_nodes = populate_tree(raw_node[:id], true, true, 100, true)

        tree_nodes << {id: parent_id, concept_id: raw_node[:id], text: node_text, children: parent_nodes, parent_reversed: true, parent_search: true, icon: icon_class, a_attr: anchor_attributes, li_attr: {class: 'komet-reverse-tree'}}

        # jump to the next node in raw_nodes
        next

      elsif boolean(parent_search)

        icon_class << '-arrow'
        anchor_attributes[:class] << ' komet-reverse-tree-node'
      end

      # if the node has no children (or no parents if doing a parent search) identify it as a leaf, otherwise it is a branch
      if !raw_node[has_relation]
        show_expander = false
      end

      node_text = raw_node[:text] + raw_node[:badge] + flags

      node = {id: get_next_id, concept_id: raw_node[:id], text: node_text, parent_reversed: parent_reversed, parent_search: parent_search, icon: icon_class, a_attr: anchor_attributes}

      if raw_node[relation].length == 0
        node[:children] = show_expander
      else
        node[:state] = {opened: 'true'}
      end

      if raw_node[relation].length > 0
        node[:children] = process_tree_level(raw_node[relation], [], parent_search_param, parent_reversed_param)
      end

      tree_nodes << node

    end

    return tree_nodes
  end

  def get_tree_node_flag(flag_name, ids_to_match)

    flag = '';

    if session['color' + flag_name]

      colors = session['color' + flag_name].find_all{|key, hash|
        hash[flag_name + 'id'].to_i.in?(ids_to_match) && hash['colorid'] != ''
      }

      colors.each do |color|
        flag = ' <span class="komet-node-' + flag_name + '-flag" style="border-color: ' + color[1]['colorid'] + ';"></span>'
      end
    end

    return flag
  end

  def dashboard

    @stated = 'true'

    if !session[:coordinatestoken]
      results =CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES_TOKEN)
      session[:coordinatestoken] = results
    end

    $log.debug("token initial #{session[:coordinatestoken].token}" )
  end

  def metadata
  end

  def version
    @version = $PROPS['PRISME.war_version']
    @version = 'Unversioned by PRISME.' if @version.nil?
    @version = {version: @version}
    render json: @version
  end

end
