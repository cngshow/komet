class KometDashboardController < ApplicationController

  before_action :setup_routes, :setup_constants, :only => [:dashboard]
  include ISAACConstants#remove me TO_DO
  #include KOMETUtilities

  def setup_routes
    routes = Rails.application.routes.named_routes.helpers.to_a
    routes_hash = {}
    routes.each do |route|
      begin
        routes_hash[route.to_s] = self.send(route)
      rescue ActionController::UrlGenerationError => ex
        if (ex.message =~ /missing required keys: \[(.*?)\]/)
          keys = $1
          keys = keys.split(',')
          keys.map! do |e|
            e.gsub!(':', '')
            e.strip
          end
          required_keys_hash = {}
          keys.each do |key|
            required_keys_hash[key.to_sym] = ':' + key.to_s
          end
          routes_hash[route.to_s] = self.send(route, required_keys_hash)
        else
          raise ex
        end
      end
    end

    $log.debug('routes hash passed to javascript is ' + routes_hash.to_s)
    gon.routes = routes_hash
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
  end

  def dashboard
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
