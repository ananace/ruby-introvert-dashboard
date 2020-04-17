# frozen_string_literal: true

module IntrovertDashboard::Components
  class Hosts < IntrovertDashboard::BaseComponent
    get '/' do
      { hosts: [] }.to_json
    end

    get '/:host' do |host|
      halt 404, { error: "Host #{host} Not Found" }.to_json
    end

    get '/:host/status' do |host|
      halt 400, { error: "Host #{host} Not Found" }.to_json
    end
  end
end
