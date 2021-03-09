# frozen_string_literal: true

require 'sinatra/base'

module IntrovertDashboard
  class BaseComponent < Sinatra::Base
    attr_reader :root

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end

    before do
      content_type 'application/json'
    end

    get '/card' do
      return pass unless self.class.card?
      return pass unless enabled?

      frag = Nokogiri::HTML.fragment('')
      Nokogiri::HTML::Builder.with(frag) do |doc|
        doc.component 'data-component': self.class.api_name, 'data-order': config[:order] do 
          render_card doc

          if component_css
            doc.style type: 'text/css' do
              doc.text component_css
            end
          end
          if component_javascript
            doc.script type: 'application/javascript' do
              doc.text component_javascript
            end
          end
        end
      end

      content_type 'text/html'
      frag.to_html
    end

    post '/register' do
      return pass unless enabled?
      return pass unless params['stream'] && event_server.has?(params['stream'])

      result = register(event_server.get(params['stream']))

      if result
        { status: 'success' }.to_json
      else
        [400, { status: 'failure' }.to_json]
      end
    end

    def config
      user_token = request.env['HTTP_AUTHENTICATION'].gsub('Bearer ', '') if request.env.key? 'HTTP_AUTHENTICATION'
      IntrovertDashboard::Config.component(self.class.api_name, user_token: user_token)
    end

    def event_server
      IntrovertDashboard::Server.settings.sse_server
    end

    def workers
      IntrovertDashboard::Server.settings.workers
    end

    def enabled?
      config[:enabled]
    end

    def register
      false
    end

    def self.api_name
      name.downcase.split('::').last
    end

    def self.available?
      true
    end

    def self.card?
      true
    end

    protected

    def render_card(doc)
      extensions = %w[html html.erb rhtml erb]
      file = extensions.map do |ext|
        file = File.join(__dir__, 'components', 'assets', "#{self.class.api_name}.#{ext}")
        next unless File.exist? file

        file
      end.reject(&:nil?).first
      return unless file

      mtime = File.stat(file).mtime
      if @component_card_changetime != mtime
        @component_card_changetime = mtime
        @component_card = File.read file
      end

      card = @component_card
      if %w[erb rhtml].include? File.extname(file)
        require 'erb'

        card = ERB.new(card, trim_mode: '-').result(binding)
      end

      doc << card
    end

    def component_javascript
      file = File.join(__dir__, 'components', 'assets', "#{self.class.api_name}.js")
      return unless File.exist? file

      mtime = File.stat(file).mtime
      if @component_javascript_changetime != mtime
        @component_javascript_changetime = mtime
        @component_javascript = File.read file
      end
      @component_javascript
    end

    def component_css
      file = File.join(__dir__, 'components', 'assets', "#{self.class.api_name}.css")
      return unless File.exist? file

      mtime = File.stat(file).mtime
      if @component_css_changetime != mtime
        @component_css_changetime = mtime
        @component_css = File.read file
      end
      @component_css
    end
  end
end
