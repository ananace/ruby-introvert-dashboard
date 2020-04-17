function init() {
  console.log("Init");

  writeClock();
  createCards();
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
      }));
    }

    Promise.all(queries.map(reflect))
      .then(function() {
        console.log("Sorting");
        $('#card-container .card').sort(function(a, b) {
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

$(function() {
  init();
});
