function init() {
  console.log("Init");

  if (hasSSE()) {
    startSSE();
  } else {
    console.log("SSE support is missing, falling back to polling.");
    checkForUpdates();
  }

  writeClock();
  createCards();
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
    var component;
    var queries = [];
    for (component in resp.data) {
      console.log("Loading card for " + component);

      queries.push(axios.get(resp.data[component], { card: component })
        .then(function(resp) {
          $(resp.data).appendTo('#card-container');
        })
        .catch(function(resp) {
          console.log('Card for ' + resp.config.card + ' failed to load;');
          if (resp.response.data) {
            console.log("-", resp.response.data.error);
          } else {
            console.log("-", resp);
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
    if (i < 10) {
        i = "0" + i;
    }
    return i;
  }

  const today = new Date();
  const h = checkTime(today.getHours());
  const m = checkTime(today.getMinutes());
  $('#clock').text(h + ':' + m);

  setTimeout(writeClock, 1000);
}

function registerGlobalHooks() {
  $('#dashboardTitle').click(function() {
    location.reload(true);
  });
  $('.nav-link').click(function(event) {
    const elem = $(event.target);
    const nav = elem.closest('.nav');
    if (nav.find('[data-default]').length == 0) {
      return;
    }

    var pb = elem.closest('.card-header').siblings('.progress');
    var id = undefined;

    const duration = parseInt(
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
      
      const bar = pb.find('.progress-bar');
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
        const bar = pb.find('.progress-bar');
        bar.css('transition', 'width 1s ease')
           .width(0);
      }
    }
    if (id !== undefined) {
      nav.data('cur-timeout', id);
    }
  });
} 

function hasSSE() {
    return !!window.EventSource;
}

var pageVersion;

var requestedEvents = [];

var eventSource;
var eventStream;
function startSSE() {
  eventSource = new EventSource('/events');
  eventSource.addEventListener("dashboard.sse", function(event) {
    const data = JSON.parse(event.data);
    console.log("New SSE link established, id " + data.id + ".");

    eventStream = data.id;

    requestedEvents.forEach(function(card) {
      axios.post('/api/' + card + '/register?stream=' + eventStream);
    });
  });
  eventSource.addEventListener('dashboard.version', function(event) {
    const data = JSON.parse(event.data);

    if (pageVersion !== undefined && pageVersion != data.version) {
      console.log("Version updated, reloading.");
      location.reload(true);
    }

    pageVersion = data.version;
  });
  eventSource.onmessage = function(event) {
    console.log("SSE link message:", event);
  };
  eventSource.onerror = function(err) {
    console.log("SSE link error:", err);

    setTimeout(function() {
      if (eventSource.readyState == 2) {
        startSSE();
      }
    }, 30000);
  };
  eventSource.onopen = function() {
    console.log("SSE link opened.");
  };
  eventSource.onclose = function() {
    console.log("SSE link closed.");
  };
}

function requestEvents(card) {
  if (requestedEvents.indexOf(card) != -1) {
    console.log("Duplicate request for events for " + card);
    return;
  }

  console.log("Registering for SSE events for " + card);

  requestedEvents.push(card);

  if (eventStream) {
    axios.post('/api/' + card + '/register?stream=' + eventStream);
  }
}

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
  const regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
  const results = regex.exec(location.search);
  return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
}

// Inject user token into headers for API requests
var axios = (function() {
  const headers = { };
  const token = getUrlParameter('token');
  if (token) {
    headers.Authentication = "Bearer " + getUrlParameter('token');
  }

  const instance = axios.create({
    headers: headers,
    maxRedirects: 0
  });

  return instance;
})();

$(function() {
  init();
});
