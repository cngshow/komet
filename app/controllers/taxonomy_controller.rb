##
# TaxonomyController -
# handles the loading of the taxonomy tree
class TaxonomyController < ApplicationController

  ##
  # load_tree_data - RESTful route for populating the taxonomy tree using an http :GET
  # The current tree node is identified in the request params with the key :id
  # If the tree is reversed so we are searching for parents of this node is identified in the request params with the key :parent_search (true/false)
  # If the parent of this node was already doing a reverse search is identified in the request params with the key :parent_reversed (true/false)
  #@return [json] the tree nodes to insert into the tree at the parent node passed in the request
  def load_tree_data

    current_id = params[:id]
    parent_search = params[:parent_search]
    ret = []

    if current_id.eql?('#')
      current_id = 0;
      ret << {id: 0, text: 'SNOMED CT Concept', parent: '#', parent_id: '#', parent_reversed: false, parent_search: parent_search, icon: 'glyphicon glyphicon-book ets-node-image-red', a_attr: { class: ''}, state: {opened: 'true'}}
    end

    if parent_search.eql?('false')
      raw_nodes = get_tree_node_children(current_id)
    else
      raw_nodes = get_tree_node_parents(current_id)
    end

    raw_nodes.each do |raw_node|

      li_classes = ''
      anchor_classes = ''
      parent_search = params[:parent_search]
      parent_reversed = params[:parent_reversed]
      has_children = true

      # should this child node be reversed and is it the first node to be reversed - comes from node data
      if parent_reversed.eql?('false') && raw_node.length > 200

        li_classes = 'ets-reverse-tree'
        anchor_classes = 'ets-reverse-tree-node'
        parent_search = 'true'
        parent_reversed = 'true'

        # li_attr: {class: li_classes}

      elsif parent_search.eql?('true')
        anchor_classes = 'ets-reverse-tree-node'
      end

      # if the node has no children (or no parents if doing a parent search) identify it as a leaf, otherwise it is a branch
      if (!parent_search.eql?('true') && raw_node[:children].length > 0) || (parent_search.eql?('true') && raw_node[:parents].length > 0)
        icon_class = 'glyphicon glyphicon-book ets-node-image-red'

      elsif (!parent_search.eql?('true') && raw_node[:children].length == 0) || (parent_search.eql?('true') && raw_node[:parents].length == 0)

        icon_class = 'glyphicon glyphicon-leaf ets-node-image-red'
        has_children = false
      end

      node = {id: raw_node[:id], text: raw_node[:text] + ' (' + raw_node[:qualifier] + ')', children: has_children, parent_id: current_id, parent_reversed: parent_reversed, parent_search: parent_search, icon: icon_class, a_attr: { class: anchor_classes}}

      if current_id == 0
        node[:parent] = '0'
      end

      ret << node
    end

    render json: ret
  end

  ##
  # get_concept_information - RESTful route for populating concept details pane using an http :GET
  # The current tree node representing the concept is identified in the request params with the key :concept_id
  # The javascript partial to render is identified in the request params with the key :partial
  #@return [javascript] render a javascript partial that rerenders all needed partials
  def get_concept_information

    concept_id = params[:concept_id].to_i
    partial = params[:partial]

    get_concept_summary(concept_id)
    get_concept_details(concept_id)
    get_concept_expression(concept_id)
    get_concept_refsets(concept_id)
    get_concept_members(concept_id)
    get_concept_references(concept_id)

    render partial: partial

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
    members << {type: 'F', type_tooltip: 'FSN', icon: 'preferred_full', acceptability: 'Preferred', term: Time.now.to_s, concept_id: '111111' }
    members << {type: 'F', type_tooltip: 'FSN', icon: 'preferred_empty', acceptability: 'Preferred', term: 'Term 2', concept_id: '222222' }

    refsets << {title: 'United States of America English language', members: members}

    @concept_details[:refsets] = refsets

    types = []

    types << {type: 'Is a (attribute)', destination: 'Death (event)', group: '0', char_type: 'Inferred' }
    types << {type: 'Associated with (attribute)', destination: 'Overwork (finding)', group: '0', char_type: 'Inferred' }

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

    @concept_refsets << {title: 'Simple Refsets Memberships', members: [{name: 'Term 1', number: Time.now.to_s},{name: 'Term 2', number: concept_id},{name: 'Term 3', number: '333333'}]}
    @concept_refsets << {title: 'Simple Map Refset', members: [{name: 'Term 4', number: '444444'},{name: 'Term 5', number: '555555'}]}
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

    @concept_references << {title: 'Is a (attribute)', references: [{term: 'Term 1', concept_id: Time.now.to_s},{term: 'Term 2', concept_id: concept_id},{term: 'Term 3', concept_id: '333333'}]}
    @concept_references << {title: 'Route of administration (attribute)', references: [{term: 'Term 4', concept_id: '444444'},{term: 'Term 5', concept_id: '555555'}]}

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

  def initialize

    @raw_tree_data = []

    @raw_tree_data << {id: 0, text: 'SNOMED CT Concept', qualifier: 'SNOMED RT+CTV3', children: [1,2,3,4,5], parents: []}

    @raw_tree_data << {id: 1, text: 'Body Structure', qualifier: 'body structure', children: [6,9], parents: [0]}
    @raw_tree_data << {id: 2, text: 'Clinical Finding', qualifier: 'clinical finding', children: [], parents: [0]}
    @raw_tree_data << {id: 3, text: 'Event', qualifier: 'event', children: [], parents: [0]}
    @raw_tree_data << {id: 4, text: 'Observable', qualifier: 'observable', children: [], parents: [0]}
    @raw_tree_data << {id: 5, text: 'Organism', qualifier: 'organism', children: [], parents: [0]}

    @raw_tree_data << {id: 6, text: 'Anatomical or acquired body structure', qualifier: 'body structure', children: [7,8], parents: [1]}
    @raw_tree_data << {id: 7, text: 'Acquired body structure', qualifier: 'body structure', children: [], parents: [6]}
    @raw_tree_data << {id: 8, text: 'Anatomical structure ', qualifier: 'body structure', children: [], parents: [6], attributes: [{label: 'Finding site', text: 'Internal body'}, {label: 'Method', text: 'Microscope'}]}

    @raw_tree_data << {id: 9, text: 'Anatomical organizational pattern', qualifier: 'body structure', children: [10,11,12], parents: [1]}
    @raw_tree_data << {id: 10, text: 'Cell to cell relationship, distinctive', qualifier: 'body structure', children: [], parents: [9], attributes: [{label: 'Finding site', text: 'Internal body'}, {label: 'Method', text: 'Microscope'}]}
    @raw_tree_data << {id: 11, text: 'Distinctive arrangement of cytoplasmic filaments', qualifier: 'cell structure', children: [], parents: [9]}
    @raw_tree_data << {id: 12, text: 'Mitochondrial aggregation within cytoplasm', qualifier: 'cell structure', children: [], parents: [9]}

  end

end
