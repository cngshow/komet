##
# TaxonomyController -
# handles the loading of the taxonomy tree
class TaxonomyController < ApplicationController
  ##
  # load_data - RESTful route for populating the taxonomy tree using an http :GET
  # The current tree node is identified in the request params with the key :id
  #@return [json] the tree nodes to insert into the tree at the parent node passed in the request
  def load_data
    parent_concept_id = params[:id]
    ret = []

    if parent_concept_id.eql?("#") #the root node id is #
      #initial load of concepts
      main_concepts = ['Body Structure', 'Clinical Finding', 'Event', 'Observable', 'Organism']
      # main_concepts = ['Body Structure']

      main_concepts.each do |concept|
        # the children : true is KEY here. This allows for the AJAX call to be done when the user clicks the down arrow to load the children
        ret << {:id => concept, :text => concept, children: true}
      end
    else
      nodes = rand(5) + 1
      nodes.times do |i|
        child_label = "#{RandomWord.adjs.next}-#{RandomWord.nouns.next}"
        ret << {id: "#{parent_concept_id}-#{child_label}", text: child_label, children: true, other_data: {drug: false, clinical_name: 'sizzling bacon'}}
      end
    end
    render json: ret
  end
end
