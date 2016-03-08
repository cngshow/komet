class LogicGraphController < ApplicationController

  include LogicGraphRest

  #curl http://localhost:3000/logic_graph/chronology/406e872b-2e19-5f5e-a71d-e4e4b2c68fe5
  def chronology
    id = params[:id]
    some_graph_chronology = LogicGraphRest.get_graph(action: ACTION_CHRONOLOGY, uuid_or_id: id, additional_req_params: {})
    json = {sememe_sequence: some_graph_chronology.sememeSequence}
    render json: json
  end

  #curl http://localhost:3000/logic_graph/version/406e872b-2e19-5f5e-a71d-e4e4b2c68fe5
  def version
    id = params[:id]
    some_graph_version = LogicGraphRest.get_graph(action: ACTION_VERSION, uuid_or_id: id, additional_req_params: {})
    json = {referenced_concept_description: some_graph_version.referencedConceptDescription}
    render json: json
  end

end
