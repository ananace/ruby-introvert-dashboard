function updateK8sInit() {
  axios.get('/api/kubernetes/version')
    .then(function(resp) {
      $('#k8sOverview .card-title .version').text(resp.data.version);
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

          nodetext += name + '<br/>\n<span style="font-size: 7pt" class="align-top text-white-50">'+errors[0]+'</span>';
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

        var podtext = '<span class="text-danger" style="font-size: 9pt">'
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
