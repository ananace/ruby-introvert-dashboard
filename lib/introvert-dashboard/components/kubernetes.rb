# frozen_string_literal: true

module IntrovertDashboard::Components
  class Kubernetes < IntrovertDashboard::BaseComponent
    class K8sWorker < IntrovertDashboard::Workers::Worker
      def initialize(config)
        @config = config
        @parties = []

        super("kubernetes|#{config[:url]}",
              binding: binding,
             &:execute)
      end

      def add_party(stream)
        party = { stream: stream, node_hash: nil, pod_hash: nil }
        puts "#{name}: Adding party #{stream.id}"
        @parties << party

        stream.closed { remove_party(stream) }
      end

      def remove_party(stream)
        puts "#{name}: Removing party #{stream.id}"
        @parties.delete_if { |p| p[:stream] == stream }

        stop! if @parties.empty?
      end

      def execute
        nodes = nil
        pods = nil

        loop do
          latest = Kubernetes.k8s_nodes(@config)
          if nodes != latest.hash
            nodes = latest.hash
            @parties.each do |party|
              party[:stream].send_event 'kubernetes.nodes', latest unless party[:node_hash] == nodes
              party[:node_hash] = nodes
            end
          end

          latest = Kubernetes.k8s_pods(@config)
          if pods != latest.hash
            pods = latest.hash
            @parties.each do |party|
              party[:stream].send_event 'kubernetes.pods', latest unless party[:pods_hash] == pods
              party[:pod_hash] = pods
            end
          end

          wait 60
        end
      end
    end

    def self.k8s_query(path, config)
      uri = URI(config[:url]).tap do |u|
        u.path = path
      end
      data = JSON.parse(Net::HTTP.get(uri), symbolize_names: true)
      return yield data if block_given?

      data
    end

    def self.k8s_nodes(config)
      nodes = k8s_query('/api/v1/nodes', config) do |data|
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

    def self.k8s_pods(config)
      pods = k8s_query('/api/v1/pods', config) do |data|
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

    def k8s_query(path)
      self.class.k8s_query(path, config)
    end

    def register(connection)
      main = workers.get("kubernetes|#{config[url]}")
      main ||= workers.register(K8sWorker.new(config))

      main.add_party(connection)

      workers.register_sse('kubernetes', connection, params: { config: config }) do
        version = nil
        loop do
          latest = Kubernetes.k8s_query('/version', config)[:gitVersion]
          connection.send_event 'kubernetes.version', { version: latest } if version != latest
          version = latest

          wait 30 * 60
        end
      end
    end

    get '/' do
      { status: 'ok' }.to_json
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
