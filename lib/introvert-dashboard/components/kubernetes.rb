# frozen_string_literal: true

module IntrovertDashboard::Components
  class Kubernetes < IntrovertDashboard::BaseComponent
    def k8s_query(path)
      uri = URI('https://kubernetes.default.svc').tap do |u|
        u.path = path
      end
      data = JSON.parse(Net::HTTP.get(uri), symbolize_names: true)
      return yield data if block_given?
      data
    end

    def render_card(doc)
      doc.div.card.k8s! style: 'width: 235px', 'data-order': 1 do
        doc.div class: 'card-header' do
          doc.nav do
            doc.ul.nav class: 'nav-xs nav-tabs card-header-tabs', role: :tablist do
              doc.li class: 'nav-item mr-auto' do
                doc.text 'K8s'
              end
              doc.li class: 'nav-item' do
                doc.a.active.k8sOverviewTab! class: 'nav-link', href: '#k8sOverview', role: :tab, 'data-toggle': :tab, 'aria-controls': 'k8sOverview', 'aria-selected': true do
                  doc.text 'Overview'
                end
              end
              doc.li class: 'nav-item' do
                doc.a.k8sNodesTab! class: 'nav-link', href: '#k8sNodes', role: :tab, 'data-toggle': :tab, 'aria-controls': 'k8sNodes' do
                  doc.text 'Nodes'
                end
              end
              doc.li class: 'nav-item' do
                doc.a.k8sPodsTab! class: 'nav-link', href: '#k8sPods', role: :tab, 'data-toggle': :tab, 'aria-controls': 'k8sPods' do
                  doc.text 'Pods'
                end
              end
            end
          end
        end

        doc.div class: 'card-body tab-content' do
          doc.div.show.active.k8sOverview! class: 'tab-pane', role: :tabpanel, 'aria-labelledby': 'k8sOverviewTab' do
            doc.h5 class: 'card-title text-white-50'
            doc.p class: 'card-text' do
              doc.text 'Nodes: '
              doc.span.k8sNodeAvailable! { doc.text '#' }
              doc.text '/'
              doc.span.k8sNodeTotal! { doc.text '#' }
              doc.br
              doc.text 'Pods: '
              doc.span.k8sPodAvailable! { doc.text '#' }
              doc.text '/'
              doc.span.k8sPodTotal! { doc.text '#' }
            end
          end
          doc.div.k8sNodes! class: 'tab-pane', role: :tabpanel, 'aria-labelledby': 'k8sNodesTab' do
            doc.h5 class: 'card-title' do
              doc.text 'Nodes'
            end
            doc.p class: 'card-text'
          end
          doc.div.k8sPods! class: 'tab-pane', role: :tabpanel, 'aria-labelledby': 'k8sPodsTab' do
            doc.h5 class: 'card-title' do
              doc.text 'Pods'
            end
            doc.p class: 'card-text'
          end
        end
      end

      doc.script do
        doc.text <<~JS
          function updateK8sInit() {
            axios.get('/api/kubernetes/version')
              .then(function(resp) {
                $('#k8sOverview .card-title').text(resp.data.version);
              });

            updateK8s();
          }

          function updateK8s() {
            axios.get('/api/kubernetes/status/nodes')
              .then(function(resp) {
                $('#k8sNodeAvailable').text(resp.data.available);
                $('#k8sNodeTotal').text(resp.data.total);

                if (resp.data.available < resp.data.total) {
                  $('#k8sNodeAvailable')
                    .removeClass('text-success')
                    .removeClass('text-danger')
                    .addClass('text-danger');

                  $('#k8sNodesTab')
                    .removeClass('text-danger')
                    .addClass('text-danger');

                  var nodetext = '<span class="text-danger">';
                  for (node in resp.data.nodes) {
                    var name = resp.data.nodes[node];
                    var errors = resp.data.errors[name];
                    var hasErrors = !!errors;
                    if (!hasErrors) { continue; }

                    nodetext += name + '<br/><span style="font-size: 7pt" class="align-top text-white-50">' + errors[0] + '</span>';
                  }
                  nodetext += '</span>';
                } else {
                  $('#k8sNodeAvailable')
                    .removeClass('text-success')
                    .removeClass('text-danger')
                    .addClass('text-success');

                  $('#k8sNodesTab')
                    .removeClass('text-danger');

                  var nodetext = '<span class="text-success">All OK</span>'
                }

                $('#k8sNodes .card-text').html(nodetext);
              });

            axios.get('/api/kubernetes/status/pods')
              .then(function(resp) {
                $('#k8sPodAvailable').text(resp.data.available);
                $('#k8sPodTotal').text(resp.data.total);

                if (resp.data.available < resp.data.total) {
                  $('#k8sPodAvailable')
                    .removeClass('text-success')
                    .removeClass('text-danger')
                    .addClass('text-danger');
                  $('#k8sPodsTab')
                    .removeClass('text-danger')
                    .addClass('text-danger');

                  var podtext = '<span class="text-danger">'
                  for (pod in resp.data.unhealthy) {
                    var name = resp.data.unhealthy[pod];
                    podtext += name + '<br/>'
                  }
                  podtext += '</span>'
                } else {
                  $('#k8sPodAvailable')
                    .removeClass('text-success')
                    .removeClass('text-danger')
                    .addClass('text-success');

                  $('#k8sPodsTab')
                    .removeClass('text-danger');

                  var podtext = '<span class="text-success">All OK</span>'
                }

                $('#k8sPods .card-text').html(podtext);
              });

            setTimeout(updateK8s, 15*1000);
          }

          $(function() { updateK8sInit(); });
        JS
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
        healthy = %[running succeeded].freeze
        Hash[data[:items].map do |pod|
          [
            "#{pod.dig(:metadata,:namespace)}/#{pod.dig(:metadata, :name)}",
            {
              healthy: healthy.include?(pod[:status][:phase].downcase),
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
