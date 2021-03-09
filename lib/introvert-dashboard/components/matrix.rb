# frozen_string_literal: true

module IntrovertDashboard::Components
  class Matrix < IntrovertDashboard::BaseComponent
    get '/' do
      {
        config: config
      }.to_json
    end
  end
end
