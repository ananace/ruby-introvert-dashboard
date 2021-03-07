require 'sinatra/base'

module IntrovertDashboard
  class Server < Sinatra::Base
    def event_server
      settings.sse_server
    end

    set :public_folder, 'public'
    set :strict_paths, false

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end

    configure :development, :production do
      enable :logging
    end

    get '/' do
      send_file File.join(settings.public_folder, 'index.html')
    end

    get '/events', provides: 'text/event-stream' do
      pass unless request.accept? 'text/event-stream'

      logger.info "Received SSE request, params: #{params}"

      stream :keep_open do |stream|
        event_server.handle_connection(stream)
        stream.callback { event_server.remove_connection(stream) }
      end
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
