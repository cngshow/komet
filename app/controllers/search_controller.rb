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
require './lib/isaac_rest/search_apis_rest'
require './lib/isaac_rest/id_apis_rest'
require './lib/isaac_rest/sememe_rest'
require './lib/isaac_rest/taxonomy_rest'

##
# SearchController -
# handles the taxonomy search functionality
class SearchController < ApplicationController
  include SearchApis, IdAPIsRest, SememeRest, ConceptConcern

  ##
  # get_assemblage_suggestions - RESTful route for populating a list suggested list of assemblages as a user types into a field via http :GET or :POST
  # The term entered by the user to search for assemblages with a request param of :term
  #@return [json] a list of matching assemblage text and ids - array of hashes {label:, value:}
  def get_assemblage_suggestions

    search_term = params[:term]
    assemblage_suggestions_data = []

    $log.debug(search_term)

    results = SearchApis.get_search_api(action: ACTION_PREFIX, additional_req_params: {query: search_term, expand: 'referencedConcept'})

    results.each do |result|

      assemblage_suggestions_data << {label: result.matchText, value: result.referencedConcept.identifiers.uuids.first}

    end

    # use this to look up all dynamic sememe assemblages "406e872b-2e19-5f5e-a71d-e4e4b2c68fe5"

    render json: assemblage_suggestions_data
  end

  ##
  # get_assemblage_recents - RESTful route for populating a list of recent assemblage searches via http :GET
  #@return [json] an array of hashes {id:, text:}
  def get_assemblage_recents

    recents_array = []

    if session[:search_assemblage_recents]
      recents_array = session[:search_assemblage_recents]
    end

    render json: recents_array
  end

  ##
  # get_search_results - RESTful route for populating the search results via http :GET
  # The query string to search for with a request param of :taxonomy_search_text
  # The type of search we are doing with a request param of :taxonomy_search_type (descriptions|sememes)
  # The number of results to fetch with a request param of :taxonomy_search_limit
  # If doing a description search the type of description to search with a request param of :description_type (fsn|synonym|definition)
  # If doing a sememe search whether to treat the query string as a string or determine its type programmatically with a request param of :treatAsString (true|false)
  # If doing a sememe search the id of an assemblage to search within with a request param of :taxonomy_search_assemblage_id
  # If doing a sememe search the display text of an assemblage to search within with a request param of :taxonomy_search_assemblage_display
  #@return [json] the search results - an array of hashes {id:, matching_text:, concept_status:, score:}
  def get_search_results

    search_results = {}
    search_data = []
    search_text = params[:taxonomy_search_text]
    search_type = params[:taxonomy_search_type]
    page_size = params[:taxonomy_search_page_size]
    page_number = params[:taxonomy_search_page_number]
    additional_params = {query: search_text, expand: 'referencedConcept,versionsLatestOnly', pageNum: page_number}

    if search_text == nil || search_text == ''
      render json: {total_rows: 0, page_data: []} and return
    end

    if page_size != nil || page_size == ''
      additional_params[:maxPageSize] =  page_size
    end

    if search_type == 'descriptions'

      description_type = params[:taxonomy_search_description_type]

      if description_type != nil
        additional_params[:descriptionType] =  description_type
      end

      # perform a description search with the parameters we set
      results = SearchApis.get_search_api(action: ACTION_DESCRIPTIONS, additional_req_params: additional_params)

      search_results[:total_number] = results.paginationData.approximateTotal
      search_results[:page_number] = results.paginationData.pageNum

      results.results.each do |result|

        # add the information to the search array to be returned
        search_data << {id: result.referencedConcept.identifiers.uuids.first, matching_terms: result.matchText, concept_status: result.referencedConcept.versions.first.conVersion.state, match_score: result.score}
      end

    elsif search_type == 'sememes'

      additional_params[:treatAsString] = params[:taxonomy_search_treat_as_string]
      assemblage = params[:taxonomy_search_assemblage_id]

      # if there is an assemblage ID in params add it to the params being passed to the search
      if assemblage != nil && assemblage != ''

        additional_params[:sememeAssemblageId] =  assemblage

        recents_array = []

        # see if the recents array already exists in the session
        if session[:search_assemblage_recents]
          recents_array = session[:search_assemblage_recents]
        end

        # only proceed if the array does not already contain the id and term that were searched for
        already_exist = recents_array.find {|recent|
          (recent['id'] == assemblage && recent['text'] == params[:taxonomy_search_assemblage_display])
        }

        if already_exist == nil

          # if the recents array has the max of 20 items remove the last item before adding a new one
          if recents_array.length == 20
            recents_array.delete_at(19)
          end

          # put the current items into the beginning of the array
          recents_array.insert(0, {id: assemblage, text: params[:taxonomy_search_assemblage_display]})

          # put the array into the session
          session[:search_assemblage_recents] = recents_array
        end

      end

      # perform a sememe search with the parameters we set
      results = SearchApis.get_search_api(action: ACTION_SEMEMES, additional_req_params: additional_params)

      search_results[:total_number] = results.paginationData.approximateTotal
      search_results[:page_number] = results.paginationData.pageNum

      results.results.each do |result|

        # add the information to the search array to be returned
        search_data << {id: result.referencedConcept.identifiers.uuids.first, matching_terms: result.matchText, concept_status: result.referencedConcept.versions.first.conVersion.state, match_score: result.score}
      end

    end

    search_results[:data] = search_data
    render json: search_results
  end

  def initialize

    @cached_results = []

  end

end