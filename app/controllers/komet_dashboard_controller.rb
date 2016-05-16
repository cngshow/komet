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
  include TaxonomyConcern, ConceptConcern, InstrumentationConcern, ISAACConstants
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

    selected_concept_id = params[:concept_id]
    parent_search = params[:parent_search]
    parent_reversed = params[:parent_reversed]
    stated = params[:stated]
    tree_walk_levels = params[:tree_walk_levels]
    tree_nodes = []
    root = selected_concept_id.eql?('#')

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

    additional_req_params = {stated: @stated}

    if boolean(parent_search)

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
      tree_nodes << {id: 0, concept_id: isaac_concept.conChronology.identifiers.uuids.first, text: isaac_concept.conChronology.description, parent: '#', parent_reversed: false, parent_search: parent_search, icon: 'glyphicon glyphicon-fire', a_attr: {class: ''}, state: {opened: 'true'}}

      selected_concept_id = 0
    else
      isaac_concept = TaxonomyRest.get_isaac_concept(uuid: selected_concept_id, additional_req_params: additional_req_params)
    end

    if isaac_concept.is_a? CommonRest::UnexpectedResponse
      render json: [] and return
    end

    raw_nodes = process_rest_concept(isaac_concept, tree_walk_levels, first_level: true, parent_search: parent_search)

    if selected_concept_id == params[:starting_concept_id]
      selected_concept_id = '#'
    end
    tree_nodes = process_tree_level(raw_nodes, tree_nodes, selected_concept_id, parent_search, parent_reversed, true)

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

    if @viewer_id == nil || @viewer_id == ''
      @viewer_id = get_next_id
    end

    get_concept_attributes(@concept_id, @stated)
    get_concept_descriptions(@concept_id, @stated)
    get_concept_sememes(@concept_id, @stated)
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
    getcoordinates_results = CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES)
    value = getcoordinates_results.languageCoordinate.to_json
    render json:  getcoordinates_results.to_json
  end

  def get_coordinatestoken
  hash = { }
  hash[:language] = params[:language]
  hash[:dialectPrefs] = params[:dialectPrefs]
  hash[:descriptionTypePrefs] = params[:descriptionTypePrefs]
  results =  CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES_TOKEN,  additional_req_params: hash)
  session[:coordinatestoken] = results
  render json:  results.to_json

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


  def process_rest_concept(concept, tree_walk_levels, first_level: false, parent_search: false, multi_path: true)

    concept_nodes = []

    node = {}
    node[:id] = concept.conChronology.identifiers.uuids.first
    node[:text] = concept.conChronology.description
    node[:has_children] = !concept.children.nil?

    if node[:has_children]
      node[:child_count] = concept.children.length

    elsif tree_walk_levels == 0 && concept.childCount != 0

      node[:child_count] = concept.childCount
      node[:has_children] = true

    else
      node[:child_count] = 0
    end

    if node[:child_count] != 0
      node[:text] << "&nbsp;&nbsp;<span class=\"badge badge-success\" title=\"kma\">#{node[:child_count]}</span>"
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

    node[:parents] = []

    # if this node has parents and we want to see all parent paths then get the IDs of each parent
    if tree_walk_levels > 0 && node[:has_parents] && !boolean(parent_search) || (tree_walk_levels > 0 && node[:parent_count] > 1 && multi_path)

      concept.parents.each do |parent|
        node[:parents] << parent.conChronology.identifiers.uuids.first
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
      concept_nodes = processed_related_concepts
    else
      $log.debug('*** data process: ' + node[:text])
      node[relation] = processed_related_concepts
      concept_nodes << node
    end

    concept_nodes
  end

  def process_tree_level (raw_nodes, tree_nodes, current_node_id, parent_search_param, parent_reversed_param, first_level)

    raw_nodes.each do |raw_node|

      anchor_attributes = { class: 'komet-context-menu', 'data-menu-type' => 'concept', 'data-menu-uuid' => raw_node[:id]}
      parent_search = parent_search_param
      parent_reversed = parent_reversed_param
      show_expander = true
      relation = :children
      has_relation = :has_children

      if boolean(parent_search)

        relation = :parents
        has_relation = :has_parents
      end

      # should this child node be reversed and is it the first node to be reversed - comes from node data
      if !boolean(parent_reversed) && raw_node[:parent_count] > 1

        anchor_attributes[:class] += ' komet-reverse-tree-node'
        parent_search = 'true'
        parent_reversed = 'true'

        # loop though all parents besides the first one (the already open path)
        raw_node[:parents].drop(1).each do |parent_id|

          parent = get_tree_node(parent_id)

          # if the node has no parents identify it as a leaf, otherwise it is a branch
          if parent[:parents].length > 0

            parent_icon_class = 'glyphicon glyphicon-book'
            parent_has_parents = true
          else

            parent_icon_class = 'glyphicon glyphicon-leaf'
            parent_has_parents = false
          end

          # add the parent node above its child, making sure that it identified as a reverse search node
          tree_nodes << {id: get_next_id, concept_id: parent[:concept_id], text: parent[:text], children: parent_has_parents, parent_reversed: true, parent_search: true, icon: parent_icon_class, a_attr: anchor_attributes, li_attr: {class: 'komet-reverse-tree'}}

        end

      elsif boolean(parent_search)
        anchor_attributes[:class] += ' komet-reverse-tree-node'
      end

      # if the node has no children (or no parents if doing a parent search) identify it as a leaf, otherwise it is a branch
      if raw_node[has_relation]
        icon_class = 'glyphicon glyphicon-book' # komet-node-image-red
      else

        icon_class = 'glyphicon glyphicon-leaf'
        show_expander = false
      end

      node = {id: get_next_id, concept_id: raw_node[:id], text: raw_node[:text], parent_reversed: parent_reversed, parent_search: parent_search, icon: icon_class, a_attr: anchor_attributes}

      # if the current ID is root, then add a 'parent' field to the node to satisfy the alternate JSON format of JSTree for this level of the tree
      if current_node_id == 0 || current_node_id == '#' || !first_level
        node[:parent] = current_node_id.to_s
      end

      if raw_node[relation].length == 0
        node[:children] = show_expander
      end

      tree_nodes << node

      if raw_node[relation].length > 0
        process_tree_level(raw_node[relation], tree_nodes, node[:id], parent_search_param, parent_reversed_param, false)
      end

    end

    return tree_nodes
  end

  def get_next_id
    return java.lang.System.nanoTime
  end

  def dashboard
    foo
    @stated = 'true'
  end

  def setup_constants
    initialize_isaac_constants #to_do, remove
    $log.debug('term_aux hash passed to javascript is ' + ISAACConstants::TERMAUX.to_s) #to_do, remove
    gon.term_aux = ISAACConstants::TERMAUX #to_do, remove

    constants_file = './config/generated/yaml/IsaacMetadataAuxiliary.yaml'
    prefix = File.basename(constants_file).split('.').first.to_sym
    json = YAML.load_file constants_file
    translated_hash = add_translations(json)
    gon.IsaacMetadataAuxiliary = translated_hash

    session[:coordinatestoken] = CoordinateRest.get_coordinate(action: CoordinateRestActions::ACTION_COORDINATES_TOKEN)

  end

  def metadata
  end

  private
  def add_translations(json)
    translated_hash = json.deep_dup
    json.keys.each do |k|
      translated_array = []
      json[k]['uuids'].each do |uuid|
        translation = JSON.parse IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TRANSLATE, uuid_or_id: uuid, additional_req_params: {"outputType" => "conceptSequence"}).to_json
        translated_array << {uuid: uuid, translation: translation}
      end
      translated_hash[k]['uuids'] = translated_array
    end
    #json_to_yaml_file(translated_hash,'reema')
    translated_hash
  end

end
