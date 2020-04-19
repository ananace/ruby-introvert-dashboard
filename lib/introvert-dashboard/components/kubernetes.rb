# frozen_string_literal: true

module IntrovertDashboard::Components
  class Kubernetes < IntrovertDashboard::BaseComponent
    def k8s_query(path)
      uri = URI(config[:url]).tap do |u|
        u.path = path
      end
      data = JSON.parse(Net::HTTP.get(uri), symbolize_names: true)
      return yield data if block_given?
      data
    end

    get '/' do
      { status: "ok" }.to_json
    end

    get '/version' do
      data = k8s_query('/version')
      {
        version: data[:gitVersion]
      }.to_json
    end

    get '/status/nodes' do
      nodes = k8s_query('/api/v1/nodes') do |data|
        Hash[data[:items].map do |node|
          [
            node[:metadata][:name],
            {
              healthy: node[:status][:conditions].find { |c| c[:type] == 'Ready' }[:status].downcase == 'true',
              conditions: Hash[node[:status][:conditions].map do |cond|
                [
                  cond[:type].to_sym,
                  {
                    status: cond[:status].downcase == 'true',
                    message: cond[:message]
                  }
                ]
              end]
            }
          ]
        end]
      end

      {
        total: nodes.count,
        available: nodes.select { |_, n| n[:healthy] }.count,

        nodes: nodes.keys,
        errors: Hash[nodes.reject { |_, n| n[:healthy] }.map do |k, n|
          messages = n[:conditions].map { |_, v| v[:message] }.uniq

          [k, messages]
        end]
      }.to_json
    end
    get '/status/pods' do
      pods = k8s_query('/api/v1/pods') do |data|
        Hash[data[:items].map do |pod|
          [
            "#{pod.dig(:metadata,:namespace)}/#{pod.dig(:metadata, :name)}",
            {
              healthy: pod[:status][:conditions].find { |c| c[:type] == 'Ready' }[:status].downcase == 'true' || pod[:status][:phase].downcase == 'succeeded',
              phase: pod[:status][:phase]
            }
          ]
        end]
      end

      {
        total: pods.count,
        available: pods.select { |_, p| p[:healthy] }.count,

        unhealthy: pods.reject { |_, p| p[:healthy] }.map { |k, _| k }
      }.to_json
    end
  end
end
