# frozen_string_literal: true

require 'psych'

module IntrovertDashboard
  class Config
    COMPONENT_DEFAULTS = {
      enabled: true,
      order: nil
    }.freeze

    def self.load(path)
      puts 'Loading config'
      @doc = deep_symbolize(Psych.load(open(path).read))
      puts @doc.inspect
    end

    def self.component(name, user_token: nil)
      name = name.to_s.downcase.to_sym unless name.is_a? Symbol
      component = @doc.dig :components, name
      user = @doc[:users]&.find { |u| u[:token] == user_token }&.dig(:components, name)

      config = COMPONENT_DEFAULTS.dup
      config.merge!(component) if component
      config.merge!(user) if user
      config
    end

    class << self
      private

      def deep_symbolize(obj)
        return obj.inject({}){|memo,(k,v)| memo[k.to_sym] =  deep_symbolize(v); memo} if obj.is_a? Hash
        return obj.inject([]){|memo,v    | memo           << deep_symbolize(v); memo} if obj.is_a? Array
        return obj
      end
    end
  end
end
