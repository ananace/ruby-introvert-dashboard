function init() {
  console.log("Init");

  writeClock();
  createCards();
  checkForUpdates();
}

function postInit() {
  console.log("All cards loaded");

  sortCards();
  registerGlobalHooks();
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
        postInit();
      });
  });
}

function sortCards() {
  $('#card-container component').sort(function(a, b) {
    return parseInt($(a).data('order')) > parseInt($(b).data('order'));
  }).appendTo('#card-container');
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

function registerGlobalHooks() {
  $('.nav-link').click(function(event) {
    var elem = $(event.target);
    var nav = elem.closest('.nav');
    var pb = elem.closest('.card-header').siblings('.progress');
    var id = undefined;
    var pbid = undefined;

    var duration = parseInt(
      elem.closest('.nav-item').data('duration') ||
      nav.data('duration') ||
      '10'
    );

    if (duration == 0) {
      return;
    }

    if (elem.data('default') === undefined) {
      id = setTimeout(function() {
        nav.find('[data-default]')
           .click();
      }, duration * 1000);

      if (pb.length == 0) {
        pb = $('<div class="progress" style="height:1px"><div class="progress-bar" role="progressbar" style="width:0"></div></div>').insertAfter(elem.closest('.card-header'));
      }
      
      var bar = pb.find('.progress-bar');
      bar.css('transition', 'none')
         .width(0);

      setTimeout(function() {
        bar.width(0)
           .css('transition', 'width '+duration+'s linear')
           .width('100%');
      }, 1);
    }

    if (nav.data('cur-timeout')) {
      clearTimeout(parseInt(nav.data('cur-timeout')));

      if (id === undefined) {
        var bar = pb.find('.progress-bar');
        bar.css('transition', 'width 1s ease')
           .width(0);
      }
    }
    if (id !== undefined) {
      nav.data('cur-timeout', id);
    }
  });
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
