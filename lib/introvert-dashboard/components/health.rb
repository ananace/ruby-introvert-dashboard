# frozen_string_literal: true

module IntrovertDashboard::Components
  class Health < IntrovertDashboard::BaseComponent
    def self.card?
      false
    end

    get '/' do
      { status: "ok" }.to_json
    end
  end
end

