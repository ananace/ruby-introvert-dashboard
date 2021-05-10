# frozen_string_literal: true

module IntrovertDashboard::Components
  class HomeAssistant < IntrovertDashboard::BaseComponent
    def self.api_query(path, config, method: :get, body: nil)
      uri = URI(config[:url]).tap do |u|
        u.path = File.join '/api', path
      end

      req = Net::HTTP.const_get(method.to_s.capitalize.to_sym).new uri.path
      req.content_type = 'application/json'
      req['authorization'] = "Bearer #{config[:token]}"

      req.body = body.to_json if body

      resp = Net::HTTP.start(uri.host, uri.port) do |http|
        http.send req
      end

      resp.value

      JSON.parse resp.body
    end

    def api_query(path, method: :get, body: nil)
      self.class.api_query(path, config, method: method, body: body)
    end

    get '/' do
      { entities: config[:entities], services: api_query('services'), info: api_query('discovery_info') }.to_json
    end

    get '/:entity' do |entity|
      halt 404, { error: "Entity #{entity} Not Found" }.to_json unless config[:entities].include? entity

      api_query(File.join 'states', entity).to_json
    end

    post '/:service/:command' do |service, command|
      entity = params['entity_id']
      data = nil
      begin
        data = JSON.parse request.body.read.to_s
      rescue JSON::ParseError
      end

      halt 400, { error: "No entity specified" }.to_json unless entity
      halt 404, { error: "Entity #{entity} Not Found" }.to_json unless config[:entities].include? entity

      api_query(File.join 'services', service, command, body: data)

      { 'status': 'success' }.to_json
    end
  end
end
