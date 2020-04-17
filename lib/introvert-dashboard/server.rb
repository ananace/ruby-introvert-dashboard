require 'sinatra/base'

module IntrovertDashboard
  class Server < Sinatra::Base
    set :public_folder, 'public'
    set :strict_paths, false

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end

    get '/' do
      send_file File.join(settings.public_folder, 'index.html')
    end

    get '/api' do
      content_type 'application/json'
      {
        paths: IntrovertDashboard::Components.constants.map do |const|
          klass = IntrovertDashboard::Components.const_get const
          next unless klass.available?

          "/api/#{klass.api_name}"
        end.reject(&:nil?)
      }.to_json
    end

    get '/cards' do
      content_type 'application/json'
        Hash[IntrovertDashboard::Components.constants.map do |const|
          klass = IntrovertDashboard::Components.const_get const
          next unless klass.available? && klass.card?

          [klass.api_name, "/api/#{klass.api_name}/card"]
        end.reject(&:nil?)].to_json
    end
  end
end
