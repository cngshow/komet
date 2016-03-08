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
##
# SearchController -
# handles the taxonomy search functionality
class SearchController < ApplicationController
  include SearchApis, SememeRest, ConceptConcern

  ##
  # get_assemblage_suggestions - RESTful route for populating the taxonomy tree using an http :GET
  # The current tree node is identified in the request params with the key :concept_id
  # If the tree is reversed so we are searching for parents of this node is identified in the request params with the key :parent_search (true/false)
  # If the parent of this node was already doing a reverse search is identified in the request params with the key :parent_reversed (true/false)
  #@return [json] the tree nodes to insert into the tree at the parent node passed in the request
  def get_assemblage_suggestions

    search_term = params[:term]

    $log.debug(search_term)

    render json: @assemblage_suggestions_data
  end

  ##
  # get_assemblage_recents - RESTful route for populating the taxonomy tree using an http :GET
  # The current tree node is identified in the request params with the key :concept_id
  # If the tree is reversed so we are searching for parents of this node is identified in the request params with the key :parent_search (true/false)
  # If the parent of this node was already doing a reverse search is identified in the request params with the key :parent_reversed (true/false)
  #@return [json] the tree nodes to insert into the tree at the parent node passed in the request
  def get_assemblage_recents

    render json: @assemblage_recents_data
  end

  ##
  # get_search_results - RESTful route for populating the taxonomy tree using an http :GET
  # The current tree node is identified in the request params with the key :concept_id
  # If the tree is reversed so we are searching for parents of this node is identified in the request params with the key :parent_search (true/false)
  # If the parent of this node was already doing a reverse search is identified in the request params with the key :parent_reversed (true/false)
  #@return [json] the tree nodes to insert into the tree at the parent node passed in the request
  def get_search_results

    search_results = {}
    search_text = params[:taxonomy_search_text]
    description_type = params[:taxonomy_search_description_type]
    assemblage = params[:taxonomy_search_assemblage]

    additional_params = {query: search_text}

    if description_type != nil
      additional_params[:descriptionType] =  description_type
    end

    results = SearchApis.get_search_api(action: ACTION_DESCRIPTIONS, additional_req_params: additional_params)
    search_data = []

    results.each do |r|
      match_nid = r.matchNid
      sememe_version = SememeRest::get_sememe(action: SememeRestActions::ACTION_VERSION, uuid_or_id: match_nid)
      search_data << {id: match_nid, concept_description: r.matchText, matching_terms: [sememe_version.sememeVersion.state.to_s, r.score.to_s]}
    end

    search_results[:total_rows] = results.length.to_s
    search_results[:page_data] = search_data
    render json: search_results
  end

  def initialize

    @assemblage_suggestions_data = []

    @assemblage_suggestions_data << {label: 'SNOMED CT Concept', value: 'SNOMED RT+CTV3'}

    @assemblage_recents_data = ['SNOMED CT Concept', 'VHAT', 'heart']

    @search_data = []
    @search_data << { id: '1234', concept_description: 'SNOMED CT Concept', matching_terms: ['SNOMED RT+CTV3', 'SNOMED CT']}
    @search_data << { id: '5678', concept_description: 'Second Term', matching_terms: ['SNOMED RT+CTV3']}
    @search_data << { id: '9012', concept_description: 'Third Term', matching_terms: ['Third Term', 'Third (3rd) Term', 'Term the Third']}


  end



end