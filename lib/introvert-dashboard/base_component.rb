# frozen_string_literal: true

require 'sinatra/base'

module IntrovertDashboard
  class BaseComponent < Sinatra::Base
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
        render_card doc
      end

      content_type 'text/html'
      frag.to_html
    end

    def config
      user_token = request.env['HTTP_AUTHENTICATION'].gsub('Bearer ', '') if request.env.key? 'HTTP_AUTHENTICATION'
      IntrovertDashboard::Config.component(self.class.api_name, user_token: user_token)
    end

    def enabled?
      config[:enabled]
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
  end
end
