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

    def k8s_nodes
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
          messages = n[:conditions].reject { |_, v| v[:status] }.map { |_, v| v[:message] }.uniq

          [k, messages]
        end]
      }
    end

    def k8s_pods
      pods = k8s_query('/api/v1/pods') do |data|
        Hash[data[:items].map do |pod|
          [
            "#{pod.dig(:metadata,:namespace)}/#{pod.dig(:metadata, :name)}",
            {
              healthy: pod.dig(:status, :conditions)&.find{ |c| c[:type] == 'Ready' }&.fetch(:status, nil)&.downcase == 'true' || pod.dig(:status, :phase)&.downcase == 'succeeded',
              phase: pod.dig(:status, :phase)
            }
          ]
        end]
      end

      {
        total: pods.count,
        available: pods.select { |_, p| p[:healthy] }.count,

        unhealthy: pods.reject { |_, p| p[:healthy] }.map { |k, _| k }
      }
    end

    def register(connection)
      params = { running: true }.dup
      connection.closed { params[:running] = false }

      Thread.new(params) do |p|
        loop do
          break unless p[:running]

          connection.send_event 'kubernetes.version', { version: k8s_query('/version')[:gitVersion] }

          connection.send_event 'kubernetes.nodes', k8s_nodes
          connection.send_event 'kubernetes.pods', k8s_pods

          sleep 30 * 60
        end
      end
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
      k8s_nodes.to_json
    end
    get '/status/pods' do
      k8s_pods.to_json
    end
  end
end
