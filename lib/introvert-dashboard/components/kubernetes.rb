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
        party = { stream: stream, node_hash: nil, pod_hash: nil, version_hash: nil }
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
        version = nil
        nodes = nil
        pods = nil

        loop do
          latest = Kubernetes.k8s_query('/version', @config)
          version = latest.hash
          @parties.each do |party|
            party[:stream].send_event 'kubernetes.version', { version: latest[:gitVersion] } unless party[:version_hash] == version
            party[:version_hash] = version
          end

          latest = Kubernetes.k8s_nodes(@config)
          nodes = latest.hash
          @parties.each do |party|
            party[:stream].send_event 'kubernetes.nodes', latest unless party[:node_hash] == nodes
            party[:node_hash] = nodes
          end

          latest = Kubernetes.k8s_pods(@config)
          pods = latest.hash
          @parties.each do |party|
            party[:stream].send_event 'kubernetes.pods', latest unless party[:pods_hash] == pods
            party[:pod_hash] = pods
          end

          wait 60
        end
      end
    end

    def self.k8s_query(path, config)
      uri = URI(config[:url]).tap do |u|
        u.path = path
      end

      opts = {
        use_ssl: uri.scheme == 'https'
      }
      opts[:ssl_version] = :TLSv1_3 if opts[:use_ssl] # Avoid potential SSLv3 issue
      if File.exist?('/var/run/secrets/kubernetes.io/serviceaccount/ca.crt')
        opts[:ca_file] = '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
      else
        opts[:verify_mode] = ::OpenSSL::SSL::VERIFY_NONE
      end

      token = config[:token]
      token ||= File.read('/var/run/secrets/kubernetes.io/serviceaccount/token') if File.exist? '/var/run/secrets/kubernetes.io/serviceaccount/token'

      data = Net::HTTP.start(uri.host, uri.port, **opts) do |http|
        req = Net::HTTP::Get.new uri.request_uri
        req['authorization'] = "Bearer #{token}" if token
        resp = http.request req
        resp.body
      end

      data = JSON.parse(data, symbolize_names: true)
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
