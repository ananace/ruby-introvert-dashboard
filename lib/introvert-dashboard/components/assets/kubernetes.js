let kubernetes = {
  applyNodes: function(data) {
    $('#k8sNodeAvailable').text(data.available);
    $('#k8sNodeTotal').text(data.total);

    if (data.available < data.total) {
      $('#k8sNodeAvailable')
        .removeClass('text-success')
        .removeClass('text-danger')
        .addClass('text-danger');

      $('#k8sNodesTab')
        .removeClass('text-danger')
        .addClass('text-danger');

      var nodetext = '<span class="text-danger">';
      for (node in data.nodes) {
        var name = data.nodes[node];
        var errors = data.errors[name];
        var hasErrors = !!errors;
        if (!hasErrors) { continue; }

        nodetext += name + '<br/>\n<span style="font-size: 7pt" class="align-top text-white-50">'+errors[0]+'</span><br/>\n';
      }
      nodetext += '\n</span>';
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
  },
  applyPods: function(data) {
    $('#k8sPodAvailable').text(data.available);
    $('#k8sPodTotal').text(data.total);

    if (data.available < data.total) {
      $('#k8sPodAvailable')
        .removeClass('text-success')
        .removeClass('text-danger')
        .addClass('text-danger');
      $('#k8sPodsTab')
        .removeClass('text-danger')
        .addClass('text-danger');

      var podtext = '<span class="text-danger" style="font-size: 9pt">'
      for (pod in data.unhealthy) {
        var name = data.unhealthy[pod];
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
  },
  applyVersion: function(data) {
    $('#k8sOverview .card-title .version').text(data.version);
  },

  poll: function() {
    axios.get('/api/kubernetes/version')
      .then(function(resp) {
        kubernetes.applyVersion(resp.data);
      });

    axios.get('/api/kubernetes/status/nodes')
      .then(function(resp) {
      });

    axios.get('/api/kubernetes/status/pods')
      .then(function(resp) {
      });

    setTimeout(kubernetes.poll, 15*1000);
  }
};

$(function() {
  if (hasSSE()) {
    eventSource.addEventListener('kubernetes.nodes', function(event) {
      const data = JSON.parse(event.data);
      kubernetes.applyNodes(data);
    });
    eventSource.addEventListener('kubernetes.pods', function(event) {
      const data = JSON.parse(event.data);
      kubernetes.applyPods(data);
    });
    eventSource.addEventListener('kubernetes.version', function(event) {
      const data = JSON.parse(event.data);
      kubernetes.applyVersion(data);
    });
    requestEvents('kubernetes');
  } else {
    kubernetes.poll();
  }
});
