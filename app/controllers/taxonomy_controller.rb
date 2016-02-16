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
  def rest_concept_version_to_json_tree(rest_concept_version, root = false)
    ret = []
    if root
      root = {}
      root[:id] = rest_concept_version.conChronology.identifiers.uuids.first
      root[:text] = rest_concept_version.conChronology.description
      root[:parent] = '#'
      root[:parent_id] = '#'
      root[:parent_reversed] = false
      # tree_data[:parent_search] = parent_search
      root[:icon] = 'glyphicon glyphicon-book ets-node-image-red'
      root[:a_attr] = {class: ''}
      root[:state] = {opened: 'true'}
      ret << root
    end

    children = rest_concept_version.children

    children.each do |child|
      if child.conChronology
        uuid = child.conChronology.identifiers.uuids.first
        desc = child.conChronology.description
        has_children = !child.children.nil?
        child_count = (has_children ? child.children.length : 0)
        badge = has_children ? "&nbsp;&nbsp;<span class=\"badge badge-success\" title=\"kma\">#{child_count}</span>" : ''
        badge += has_children ? "&nbsp;&nbsp;<sup>#{child_count}</sup>" : ''
        desc << badge
        # @raw_tree_data << {id: 1, text: 'Body Structure', qualifier: 'body structure', children: [6, 9], parents: [0]}
        child_node = {}
        child_node[:id] = uuid
        child_node[:text] = desc
        child_node[:qualifier] = desc
        child_node[:parent] = root[:id] if root # todo we need to know parents
        child_node[:parent_id] = root[:id] if root # todo we need to know parents
        child_node[:children] = has_children
        child_node[:child_count] = child_count
        ret << child_node
      end
    end
    ret
  end

  ##
  # load_tree_data - RESTful route for populating the taxonomy tree using an http :GET
  # The current tree node is identified in the request params with the key :concept_id
  # If the tree is reversed so we are searching for parents of this node is identified in the request params with the key :parent_search (true/false)
  # If the parent of this node was already doing a reverse search is identified in the request params with the key :parent_reversed (true/false)
  #@return [json] the tree nodes to insert into the tree at the parent node passed in the request
  def load_tree_data

    current_id = params[:concept_id]
    parent_search = params[:parent_search]
    tree_nodes = []
    root = current_id.eql?('#')

    if root
      # load the ISAAC root node and children
      isaac_root = TaxonomyRest.get_isaac_root
      tree_nodes = rest_concept_version_to_json_tree(isaac_root, true)
      # current_id = 0
      # ret << {id: 0, text: 'SNOMED CT Concept', parent: '#', parent_id: '#', parent_reversed: false, parent_search: parent_search, icon: 'glyphicon glyphicon-book ets-node-image-red', a_attr: {class: ''}, state: {opened: 'true'}}
    else
      isaac_concept = TaxonomyRest.get_isaac_concept(current_id)
      tree_nodes = rest_concept_version_to_json_tree(isaac_concept)
    end

=begin
    if parent_search.eql?('false')
      raw_nodes = get_tree_node_children(current_id)
    else
      raw_nodes = get_tree_node_parents(current_id)
    end
=end

    tree_nodes.each do |raw_node|

      anchor_classes = ''
      parent_search = params[:parent_search]
      parent_reversed = params[:parent_reversed]

      # should this child node be reversed and is it the first node to be reversed - comes from node data
      if parent_reversed.eql?('false') && raw_node[:parents].length > 1
#todo Tim we commented raw nodes out.   Need help here.
        li_classes = 'ets-reverse-tree'
        anchor_classes = 'ets-reverse-tree-node'
        parent_search = 'true'
        parent_reversed = 'true'
        # loop though all parents besides the first one (the already open path)
        raw_node[:parents].drop(1).each do |parent_id|

          parent = get_tree_node(parent_id)

          # if the node has no parents identify it as a leaf, otherwise it is a branch
          if parent[:parents].length > 0

            parent_icon_class = 'glyphicon glyphicon-book ets-node-image-red'
            parent_has_parents = true
          else

            parent_icon_class = 'glyphicon glyphicon-leaf ets-node-image-red'
            parent_has_parents = false
          end

          # add the parent node above its child, making sure that it identified as a reverse search node
          tree_nodes << {id: get_next_tree_id, concept_id: parent[:concept_id], text: parent[:text] + ' (' + parent[:qualifier] + ')', children: parent_has_parents, parent_id: current_id, parent_reversed: true, parent_search: true, icon: parent_icon_class, a_attr: { class: 'ets-reverse-tree-node'}, li_attr: {class: 'ets-reverse-tree'}}

        end

        # loop though all parents besides the first one (the already open path)
        raw_node[:parents].drop(1).each do |parent_id|

          parent = get_tree_node(parent_id)

          # if the node has no parents identify it as a leaf, otherwise it is a branch
          if parent[:parents].length > 0

            parent_icon_class = 'glyphicon glyphicon-book ets-node-image-red'
            parent_has_parents = true
          else

            parent_icon_class = 'glyphicon glyphicon-leaf ets-node-image-red'
            parent_has_parents = false
          end

          # add the parent node above its child, making sure that it identified as a reverse search node
          tree_nodes << {id: get_next_tree_id, concept_id: parent[:concept_id], text: parent[:text] + ' (' + parent[:qualifier] + ')', children: parent_has_parents, parent_id: current_id, parent_reversed: true, parent_search: true, icon: parent_icon_class, a_attr: { class: 'ets-reverse-tree-node'}, li_attr: {class: 'ets-reverse-tree'}}

        end

        # li_attr: {class: li_classes}
#todo TIM?
        # # loop though all parents besides the first one (the already open path)
        # raw_node[:parents].drop(1).each do |parent_id|
        #
        #   parent = get_tree_node(parent_id)
        #
        #   # if the node has no parents identify it as a leaf, otherwise it is a branch
        #   if parent[:parents].length > 0
        #
        #     parent_icon_class = 'glyphicon glyphicon-book ets-node-image-red'
        #     parent_has_parents = true
        #   else
        #
        #     parent_icon_class = 'glyphicon glyphicon-leaf ets-node-image-red'
        #     parent_has_parents = false
        #   end
        #
        #   # add the parent node above its child, making sure that it identified as a reverse search node
        #   tree_nodes << {id: get_next_tree_id, concept_id: parent[:concept_id], text: parent[:text] + ' (' + parent[:qualifier] + ')', children: parent_has_parents, parent_id: current_id, parent_reversed: true, parent_search: true, icon: parent_icon_class, a_attr: { class: 'ets-reverse-tree-node'}, li_attr: {class: 'ets-reverse-tree'}}
        #
        # end

      elsif parent_search.eql?('true')
        anchor_classes = 'ets-reverse-tree-node'
      end
=begin

      # if the node has no children (or no parents if doing a parent search) identify it as a leaf, otherwise it is a branch
      if (!parent_search.eql?('true') && raw_node[:children].length > 0) || (parent_search.eql?('true') && raw_node[:parents].length > 0)
        icon_class = 'glyphicon glyphicon-book ets-node-image-red'

      elsif (!parent_search.eql?('true') && raw_node[:children].length == 0) || (parent_search.eql?('true') && raw_node[:parents].length == 0)

        icon_class = 'glyphicon glyphicon-leaf ets-node-image-red'
        has_children = false
      end

      # node = {id: raw_node[:id], text: raw_node[:text] + ' (' + raw_node[:qualifier] + ')', children: has_children, parent_id: current_id, parent_reversed: parent_reversed, parent_search: parent_search, icon: icon_class, a_attr: {class: anchor_classes}}
=end
      icon_class =
          case raw_node[:child_count]
            when NIL then
              'glyphicon glyphicon-fire ets-node-image-red'
            when 0 then
              'glyphicon glyphicon-leaf ets-node-image-red'
            else
              'glyphicon glyphicon-book ets-node-image-red'
          end

      raw_node[:icon] = icon_class
      raw_node[:a_attr] = {class: anchor_classes}
      raw_node[:parent_reversed] = parent_reversed
      raw_node[:parent_search] = parent_search
    end

    render json: tree_nodes
  end

  ##
  # get_concept_information - RESTful route for populating concept details pane using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # The javascript partial to render is identified in the request params with the key :partial
  #@return [javascript] render a javascript partial that re-renders all needed partials
  def get_concept_information

    concept_id = params[:concept_id].to_i
    partial = params[:partial]

    get_concept_summary(concept_id)
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

    @concept_diagram = {
        fsn: @raw_tree_data[concept_id].fetch(:text),
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

    @concept_summary = @raw_tree_data[concept_id]

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
    # @p = render_to_string partial: 'ets_dashboard/concept_detail/kma', locals: {local_kma: @current, local_random: @kma}
    @local_kma3 = 'oh yea!'
    @test = view_context.render 'ets_dashboard/concept_detail/kma3' #, locals: {local_kma3: 'another one'}
    puts @test
    # render :json => {time: @current, kma: @kma}
  end

  def test_render_partial
    sleep(2)
    @kma2 = Time.now.to_s
    @greg = get_a_number
    # stored_content
    render partial: 'ets_dashboard/concept_detail/kma2', locals: {local_kma: @kma2, local_random: @greg, bacon: 'awesome!'}
  end

  def get_a_number
    rand(20)
  end

  def stored_content
    content_for(:storage, render(partial: 'ets_dashboard/concept_detail/kma2', locals: {local_random: get_a_number}))
  end
=end

  ##
  # This method gets called when the diagram tab is selected. It simply pulls the concept data and renders the concept diagram html page.
  # The concept_diagram partial makes an Ajax call (svg_diagram) to render the JavaScript for the generated SVG
  def render_concept_diagram
    get_concept_diagram(params[:concept_id])
    respond_to do |format|
      format.html { render partial: 'ets_dashboard/concept_detail/concept_diagram' }
    end
  end

  ##
  # This method is called to render the JavaScript partial which renders the SVG image. This method is called via AJAX from the concept_diagram.html.erb file
  def svg_diagram
    get_concept_diagram(params[:concept_id])
    respond_to do |format|
      format.js { render partial: 'ets_dashboard/concept_detail/svg_diagram' }
    end
  end

end