# frozen_string_literal: true

module IntrovertDashboard::Components
  class Status < IntrovertDashboard::BaseComponent
    def self.card?
      false
    end

    def initialize *args
      super

      @version = Time.now
    end

    get '/health' do
      { status: "ok" }.to_json
    end

    get '/version' do
      { version: @version.to_i.to_s(36) }.to_json
    end
  end
end

