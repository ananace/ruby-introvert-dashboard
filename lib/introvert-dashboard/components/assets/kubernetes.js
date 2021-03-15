var kubernetes = {
  applyNodes: function(data) {
    let nodes = $('#k8s span[data-value="nodes.available"]');
    nodes.text(data.available);
    $('#k8s span[data-value="nodes.total"]').text(data.total);

    var nodetext;
    if (data.available < data.total) {
      nodes
        .removeClass('text-success')
        .removeClass('text-danger')
        .addClass('text-danger');

      $('#k8sNodesTab')
        .removeClass('text-danger')
        .addClass('text-danger');

      nodetext = '<span class="text-danger">';
      var node;
      for (node in data.nodes) {
        var name = data.nodes[node];
        var errors = data.errors[name];
        var hasErrors = !!errors;
        if (!hasErrors) { continue; }

        nodetext += name + '<br/>\n<span style="font-size: 7pt" class="align-top text-white-50">'+errors[0]+'</span><br/>\n';
      }
      nodetext += '\n</span>';
    } else {
      nodes
        .removeClass('text-success')
        .removeClass('text-danger')
        .addClass('text-success');

      $('#k8sNodesTab')
        .removeClass('text-danger');

      nodetext = '<span class="text-success">All OK</span>'
    }

    $('#k8sNodes .card-text').html(nodetext);
  },
  applyPods: function(data) {
    let pods = $('#k8s span[data-value="pods.available"]');
    pods.text(data.available);
    $('#k8s span[data-value="pods.total"]').text(data.total);

    var podtext;
    if (data.available < data.total) {
      pods
        .removeClass('text-success')
        .removeClass('text-danger')
        .addClass('text-danger');
      $('#k8sPodsTab')
        .removeClass('text-danger')
        .addClass('text-danger');

      var pod;
      podtext = '<span class="text-danger" style="font-size: 9pt">'
      for (pod in data.unhealthy) {
        var name = data.unhealthy[pod];
        podtext += name + '<br/>'
      }
      podtext += '</span>'
    } else {
      pods
        .removeClass('text-success')
        .removeClass('text-danger')
        .addClass('text-success');

      $('#k8sPodsTab')
        .removeClass('text-danger');

      podtext = '<span class="text-success">All OK</span>'
    }

    $('#k8sPods .card-text').html(podtext);
  },
  applyVersion: function(data) {
    $('#k8sOverview .card-title .version').text(data.version);
  }
};

$(function() {
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
});
