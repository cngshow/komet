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

##
# TaxonomyController -
# handles the loading of the taxonomy tree
class TaxonomyController < ApplicationController
  include ConceptConcern, InstrumentationConcern

  after_filter :byte_size unless Rails.env.production?

  def taxonomy
    @stated = 'false'
  end

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
      tree_walk_levels = 2
    else
      tree_walk_levels = tree_walk_levels.to_i + 1
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
  # The javascript partial to render is identified in the request params with the key :partial
  #@return [javascript] render a javascript partial that re-renders all needed partials
  def get_concept_information

    concept_id = params[:concept_id]
    partial = params[:partial]

    get_concept_summary(concept_id)
    get_concept_sememes(concept_id)
    get_concept_details(concept_id)
    get_concept_diagram(concept_id)
    get_concept_expression(concept_id)
    get_concept_refsets(concept_id)
    get_concept_members(concept_id)
    get_concept_references(concept_id)

    render partial: partial

  end

  ##
  # get_concept_diagram - RESTful route for populating concept diagram tab using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the @concept_diagram variable
  def get_concept_diagram(concept_id = nil)

    # if concept_id == nil && params[:concept_id]
    concept_id = params[:concept_id].to_i
    # end

    # todo Reema - need to hook this up to get data from web services, as the tree data will not match the static IDs anymore
    @concept_diagram = {
        fsn: @raw_tree_data[1].fetch(:text),
    }

  end

  ##
  # get_concept_summary - RESTful route for populating concept summary tab using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the @concept_summary variable
  def get_concept_summary(concept_id = nil)

    if concept_id == nil && params[:concept_id]
      concept_id = params[:concept_id].to_i
    end

    @descriptions =  descriptions(concept_id)

  end

  ##
  # get_concept_sememes - RESTful route for populating concept sememes section using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the @concept_sememes variable
  def get_concept_sememes(concept_id = nil)

    if concept_id == nil && params[:concept_id]
      concept_id = params[:concept_id].to_i
    end

    @concept_sememes = get_attached_sememes(concept_id) # descriptions(concept_id)

  end

  ##
  # get_concept_details - RESTful route for populating concept details tab using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the @concept_details variable
  def get_concept_details(concept_id = nil)

    if concept_id == nil && params[:concept_id]
      concept_id = params[:concept_id].to_i
    end

    @concept_details = {}
    @concept_details[:description] = 'Death from overwork (event)'
    @concept_details[:concept_id] = concept_id
    @concept_details[:status] = 'Fully defined , Active'

    refsets = []

    members = []
    members << {type: 'F', type_tooltip: 'FSN', icon: 'preferred_full', acceptability: 'Preferred', term: Time.now.to_s, concept_id: '111111'}
    members << {type: 'F', type_tooltip: 'FSN', icon: 'preferred_empty', acceptability: 'Preferred', term: 'Term 2', concept_id: '222222'}

    refsets << {title: 'United States of America English language', members: members}

    @concept_details[:refsets] = refsets

    types = []

    types << {type: 'Is a (attribute)', destination: 'Death (event)', group: '0', char_type: 'Inferred'}
    types << {type: 'Associated with (attribute)', destination: 'Overwork (finding)', group: '0', char_type: 'Inferred'}

    @concept_details[:types] = types

  end

  ##
  # get_concept_expression - RESTful route for populating concept expression tab using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the @concept_expressions variable
  def get_concept_expression(concept_id = nil)

    if concept_id == nil && params[:concept_id]
      concept_id = params[:concept_id].to_i
    end

    @concept_expressions = []

    expression_array = []

    expression_array << {type: 'level', value: '1'}
    expression_array << {type: 'symbol', value: '==='}
    expression_array << {type: 'id', value: concept_id}
    expression_array << {type: 'description', value: Time.now.to_s}


    @concept_expressions << {title: 'Pre-coordinated Expression', expression: expression_array}

    expression_array = []

    expression_array << {type: 'level', value: '1'}
    expression_array << {type: 'symbol', value: '==='}
    expression_array << {type: 'id', value: '3415004'}
    expression_array << {type: 'description', value: 'Cyanosis (finding)'}
    expression_array << {type: 'symbol', value: '+'}

    expression_array << {type: 'level', value: '2'}
    expression_array << {type: 'id', value: '363696006'}
    expression_array << {type: 'description', value: 'Neonatal cardiovascular disorder (disorder)'}
    expression_array << {type: 'symbol', value: ':'}

    @concept_expressions << {title: 'Expression from Stated Concept Definition', expression: expression_array}

    expression_array = []

    expression_array << {type: 'level', value: '1'}
    expression_array << {type: 'symbol', value: '==='}
    expression_array << {type: 'id', value: '3415004'}
    expression_array << {type: 'description', value: 'Cyanosis (finding)'}
    expression_array << {type: 'symbol', value: '+'}

    expression_array << {type: 'level', value: '2'}
    expression_array << {type: 'id', value: '363696006'}
    expression_array << {type: 'description', value: 'Neonatal cardiovascular disorder (disorder)'}
    expression_array << {type: 'symbol', value: ':'}

    expression_array << {type: 'level', value: '3'}
    expression_array << {type: 'id', value: '246454002'}
    expression_array << {type: 'description', value: 'Occurrence (attribute)'}
    expression_array << {type: 'symbol', value: '='}
    expression_array << {type: 'id', value: '255407002'}
    expression_array << {type: 'description', value: 'Neonatal (qualifier value)'}

    expression_array << {type: 'level', value: '3'}
    expression_array << {type: 'id', value: '363698007'}
    expression_array << {type: 'description', value: 'Finding site (attribute)'}
    expression_array << {type: 'symbol', value: '='}
    expression_array << {type: 'id', value: '113257007'}
    expression_array << {type: 'description', value: 'Structure of cardiovascular system (body structure)'}

    @concept_expressions << {title: 'Expression from Inferred Concept Definition', expression: expression_array}

  end

  ##
  # get_concept_refsets - RESTful route for populating concept refsets tab using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the @concept_refsets variable
  def get_concept_refsets(concept_id = nil)

    if concept_id == nil && params[:concept_id]
      concept_id = params[:concept_id].to_i
    end

    @concept_refsets = []

    @concept_refsets << {title: 'Simple Refsets Memberships', members: [{name: 'Term 1', number: Time.now.to_s}, {name: 'Term 2', number: concept_id}, {name: 'Term 3', number: '333333'}]}
    @concept_refsets << {title: 'Simple Map Refset', members: [{name: 'Term 4', number: '444444'}, {name: 'Term 5', number: '555555'}]}
    @concept_refsets << {title: 'Attribute Value Refset', members: [{name: 'Term 6', number: '666666'}]}
    @concept_refsets << {title: 'Association Refset', members: []}

  end

  ##
  # get_concept_references - RESTful route for populating concept references tab using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the @concept_references variable
  def get_concept_references(concept_id = nil)

    if concept_id == nil && params[:concept_id]
      concept_id = params[:concept_id].to_i
    end

    @concept_references = []

    @concept_references << {title: 'Is a (attribute)', references: [{term: 'Term 1', concept_id: Time.now.to_s}, {term: 'Term 2', concept_id: concept_id}, {term: 'Term 3', concept_id: '333333'}]}
    @concept_references << {title: 'Route of administration (attribute)', references: [{term: 'Term 4', concept_id: '444444'}, {term: 'Term 5', concept_id: '555555'}]}

  end

  ##
  # get_concept_members - RESTful route for populating concept members tab using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the @concept_members variable
  def get_concept_members(concept_id = nil)

    if concept_id == nil && params[:concept_id]
      concept_id = params[:concept_id].to_i
    end

    @concept_members = []

    @concept_members << {term: 'Term 1', concept_id: Time.now.to_s}
    @concept_members << {term: 'Term 2', concept_id: concept_id}
    @concept_members << {term: 'Term 3', concept_id: '333333'}

  end

  ##
  # get_concept_parent_path - RESTful route for populating concept members tab using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # @return none - setting the @concept_members variable
  def get_concept_parent_path(concept_id = nil)

    if concept_id == nil && params[:concept_id]
      concept_id = params[:concept_id].to_i
    end

    @concept_members = []

    @concept_members << {term: 'Term 1', concept_id: Time.now.to_s}
    @concept_members << {term: 'Term 2', concept_id: concept_id}
    @concept_members << {term: 'Term 3', concept_id: '333333'}

  end

  def process_rest_concept(concept, tree_walk_levels, first_level: false, parent_search: false, multi_path: true)
    $log.debug('*** rest_concept_version_to_json_tree called: ' + concept.conChronology.description)
    concept_nodes = []

    node = {}
    uuid = concept.conChronology.identifiers.uuids.first
    desc = concept.conChronology.description
    node[:has_children] = !concept.children.nil?
    child_count = (node[:has_children] ? concept.children.length : 0)
    badge = node[:has_children] ? "&nbsp;&nbsp;<span class=\"badge badge-success\" title=\"kma\">#{child_count}</span>" : ''
    desc << badge

    node[:id] = uuid
    node[:text] = desc
    node[:child_count] = child_count
    node[:has_parents] = !concept.parents.nil?
    parent_count = node[:has_parents] ? concept.parents.length : 0
    node[:parent_count] = parent_count
    parents = []

    # if this node has parents and we want to see all parent paths then get the IDs of each parent
    if tree_walk_levels > 1 && node[:has_parents] && !boolean(parent_search) || (parent_count > 1 && multi_path)

      concept.parents.each do |parent|
        parents << parent.conChronology.identifiers.uuids.first
      end
    end

    node[:parents] = parents
    relation = :children

    # if we are walking up the tree toward the root node get the parents of the current node, otherwise get the children
    if tree_walk_levels > 1 && boolean(parent_search) && !concept.parents.nil?

      relation = :parents
      related_concepts = concept.parents

    elsif tree_walk_levels > 1 && !boolean(parent_search) && !concept.children.nil?
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
          tree_nodes << {id: get_next_tree_id, concept_id: parent[:concept_id], text: parent[:text], children: parent_has_parents, parent_reversed: true, parent_search: true, icon: parent_icon_class, a_attr: anchor_attributes, li_attr: {class: 'komet-reverse-tree'}}

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

      node = {id: get_next_tree_id, concept_id: raw_node[:id], text: raw_node[:text], parent_reversed: parent_reversed, parent_search: parent_search, icon: icon_class, a_attr: anchor_attributes}

      # if the current ID is root, then add a 'parent' field to the node to satisfy the alternate JSON format of JSTree for this level of the tree
      if current_node_id == 0 || current_node_id == '#' || !first_level
        node[:parent] = current_node_id.to_s
      end

      if raw_node[relation].length == 0
        node[:children] = show_expander
      end

      tree_nodes << node
      $log.debug('### tree process: ' + node[:text])

      if raw_node[relation].length > 0
        process_tree_level(raw_node[relation], tree_nodes, node[:id], parent_search_param, parent_reversed_param, false)
      end

    end

    return tree_nodes
  end

  def get_tree_node (id)
    return @raw_tree_data[id]
  end

  def get_tree_node_children (parent_id)

    children = []
    child_ids = @raw_tree_data[parent_id.to_i][:children]

    child_ids.each do |child_id|
      children << @raw_tree_data[child_id]
    end

    return children
  end

  def get_tree_node_parents (child_id)

    parents = []
    parent_ids = @raw_tree_data[child_id.to_i][:parents]

    parent_ids.each do |parent_id|
      parents << @raw_tree_data[parent_id]
    end

    return parents
  end

  def get_next_tree_id
    return java.lang.System.nanoTime
  end

  def initialize

    @stated = 'false'

    @raw_tree_data = []

    @raw_tree_data << {concept_id: 0, text: 'SNOMED CT Concept', qualifier: 'SNOMED RT+CTV3', children: [1,2,3,4,5], parents: []}

    @raw_tree_data << {concept_id: 1, text: 'Body Structure', qualifier: 'body structure', children: [6,9], parents: [0]}
    @raw_tree_data << {concept_id: 2, text: 'Clinical Finding', qualifier: 'clinical finding', children: [], parents: [0]}
    @raw_tree_data << {concept_id: 3, text: 'Event', qualifier: 'event', children: [], parents: [0]}
    @raw_tree_data << {concept_id: 4, text: 'Observable', qualifier: 'observable', children: [], parents: [0]}
    @raw_tree_data << {concept_id: 5, text: 'Organism', qualifier: 'organism', children: [], parents: [0]}

    @raw_tree_data << {concept_id: 6, text: 'Anatomical or acquired body structure', qualifier: 'body structure', children: [7,8], parents: [1]}
    @raw_tree_data << {concept_id: 7, text: 'Anatomical idea', qualifier: 'body structure', children: [], parents: [6,9]}
    @raw_tree_data << {concept_id: 8, text: 'Anatomical structure ', qualifier: 'body structure', children: [], parents: [6], attributes: [{label: 'Finding site', text: 'Internal body'}, {label: 'Method', text: 'Microscope'}]}

    @raw_tree_data << {concept_id: 9, text: 'Anatomical organizational pattern', qualifier: 'body structure', children: [10,11,12], parents: [1]}
    @raw_tree_data << {concept_id: 10, text: 'Cell to cell relationship, distinctive', qualifier: 'body structure', children: [], parents: [9], attributes: [{label: 'Finding site', text: 'Internal body'}, {label: 'Method', text: 'Microscope'}]}
    @raw_tree_data << {concept_id: 11, text: 'Distinctive arrangement of cytoplasmic filaments', qualifier: 'cell structure', children: [], parents: [9]}
    @raw_tree_data << {concept_id: 12, text: 'Anatomical idea', qualifier: 'cell structure', children: [], parents: [9,6]}

  end

=begin
  def test_ajax_js
    @current = Time.now.to_s
    @kma = rand(10)
    # render_to_string(:action => "users/profile", :layout => false)
    # @p = render_to_string partial: 'komet_dashboard/concept_detail/kma', locals: {local_kma: @current, local_random: @kma}
    @local_kma3 = 'oh yea!'
    @test = view_context.render 'komet_dashboard/concept_detail/kma3' #, locals: {local_kma3: 'another one'}
    puts @test
    # render :json => {time: @current, kma: @kma}
  end

  def test_render_partial
    sleep(2)
    @kma2 = Time.now.to_s
    @greg = get_a_number
    # stored_content
    render partial: 'komet_dashboard/concept_detail/kma2', locals: {local_kma: @kma2, local_random: @greg, bacon: 'awesome!'}
  end

  def get_a_number
    rand(20)
  end

  def stored_content
    content_for(:storage, render(partial: 'komet_dashboard/concept_detail/kma2', locals: {local_random: get_a_number}))
  end
=end

  ##
  # This method gets called when the diagram tab is selected. It simply pulls the concept data and renders the concept diagram html page.
  # The concept_diagram partial makes an Ajax call (svg_diagram) to render the JavaScript for the generated SVG
  def render_concept_diagram
    get_concept_diagram(params[:concept_id])
    respond_to do |format|
      format.html { render partial: 'komet_dashboard/concept_detail/concept_diagram' }
    end
  end

  ##
  # This method is called to render the JavaScript partial which renders the SVG image. This method is called via AJAX from the concept_diagram.html.erb file
  def svg_diagram
    get_concept_diagram(params[:concept_id])
    respond_to do |format|
      format.js { render partial: 'komet_dashboard/concept_detail/svg_diagram' }
    end
  end

end
