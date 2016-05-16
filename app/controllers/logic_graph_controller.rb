class LogicGraphController < ApplicationController

  include LogicGraphRest

  #curl http://localhost:3000/logic_graph/chronology/406e872b-2e19-5f5e-a71d-e4e4b2c68fe5
  def chronology
    id = params[:id]
    id = "251be9d9-0193-3c98-9d11-317658983101"
    stated = params[:stated]
    some_graph_chronology = LogicGraphRest.get_graph(action: ACTION_CHRONOLOGY, uuid_or_id: id, additional_req_params: {stated: stated})
    json = {sememe_sequence: some_graph_chronology.sememeSequence}
    #render json: json
    render json: some_graph_chronology.to_json
  end

  #isaac_root ->  Concrete domain operator
  #curl http://localhost:3000/logic_graph/version/406e872b-2e19-5f5e-a71d-e4e4b2c68fe5
  def version
    id = params[:id]
    stated = params[:stated]
    some_graph_version = LogicGraphRest.get_graph(action: ACTION_VERSION, uuid_or_id: id, additional_req_params: {stated: stated})
    render json: some_graph_version.to_json
  end

end
