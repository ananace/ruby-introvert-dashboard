function init() {
  console.log("Init");

  writeClock();
  createCards();
  checkForUpdates();
}

function reflect(promise){
    return promise.then(function(v){ return {v:v, status: "fulfilled" }},
                        function(e){ return {e:e, status: "rejected" }});
}

function createCards() {
  axios.get('/cards').then(function(resp) {
    queries = []
    for (component in resp.data) {
      console.log("Loading card for " + component);
      queries.push(axios.get(resp.data[component])
        .then(function(resp) {
          $(resp.data).appendTo('#card-container');
        })
        .catch(function(resp) {
          console.log('Card for ' + component + ' failed to load');
          if (resp.data) {
            console.log(resp.data.error);
          } else {
            console.log(resp);
          }
        })
      );
    }

    Promise.all(queries.map(reflect))
      .then(function() {
        console.log("All cards loaded, sorting");
        $('#card-container component').sort(function(a, b) {
          return parseInt($(a).data('order')) > parseInt($(b).data('order'));
        }).appendTo('#card-container');
      });
  });
}

function writeClock() {
  function checkTime(i) {
    if (i < 10) {i = "0" + i};
    return i;
  }

  var today = new Date();
  var h = checkTime(today.getHours());
  var m = checkTime(today.getMinutes());
  $('#clock').text(h + ':' + m);

  setTimeout(writeClock, 1000);
}

var pageVersion;
function checkForUpdates() {
  axios.get('/api/status/version')
    .then(function(resp) {
      if (pageVersion !== undefined && pageVersion != resp.data.version) {
        console.log("Version updated, reloading.");
        location.reload(true);
      }

      pageVersion = resp.data.version;
    });

  setTimeout(checkForUpdates, 30000);
}

function getUrlParameter(name) {
  name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
  var regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
  var results = regex.exec(location.search);
  return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
};

// Inject user token into headers for API requests
var axios = (function() {
  headers = { };
  token = getUrlParameter('token');
  if (token) {
    headers.Authentication = "Bearer " + getUrlParameter('token');
  }

  instance = axios.create({
    headers: headers,
    maxRedirects: 0
  });

  return instance;
})();

$(function() {
  init();
});
