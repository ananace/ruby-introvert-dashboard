var weather = {
  apply: function(input) {
    var days = ['now','today','tomorrow'];
    // const hours = new Date().getHours();
    // const isDayTime = hours > 6 && hours < 20;
    var i;
    for (i in days) {
      var day = days[i];
      var data = undefined;
      var curdata = undefined;
      if (day == 'now') {
        data = input['today'];
        curdata = data.by_hour[0];
      } else {
        data = input[day];
        curdata = data.average;
      }

      weather.applyData(day, curdata, data);
    }
  },

  applyData: function(day, curdata, data) {
    $('#weather i[data-value="weather.' + day +'.icon"]')
      .attr('class', 'wi ' + curdata.symbol);
    $('#weather span[data-value="weather.' + day +'.temperature"]').text(curdata.temperature);

    if (day !== 'now')
    {
      $('#weather span[data-value="weather.' + day + '.day_temp"]').text(data.average_day.temperature);
      $('#weather span[data-value="weather.' + day + '.night_temp"]').text(data.average_night.temperature);
    }

    $('#weather i[data-value="weather.' + day + '.wind_dir"]')
      .attr('class', 'wi wi-wind from-' + Math.round(curdata.wind.dir) + '-deg');
    $('#weather span[data-value="weather.' + day + '.wind_speed"]').text(curdata.wind.speed);
    $('#weather span[data-value="weather.' + day + '.humidity"]').text(curdata.humidity);

    if (curdata.precipitation.category_id != 0) {
      const pmax = Math.round(curdata.precipitation.max * 10) / 10;
      const pmin = Math.round(curdata.precipitation.min * 10) / 10;

      $('#weather span[data-value="weather.' + day + '.pmin"]').text(pmin);
      $('#weather span[data-value="weather.' + day + '.pmax"]').text(pmax);
      $('#weather span[data-value="weather.' + day + '.pcat"]').text(curdata.precipitation.category);

      $('#weather span[data-value="weather.' + day + '.precipitation"]').removeClass('d-none');
    } else {
      $('#weather span[data-value="weather.' + day + '.precipitation"]').addClass('d-none');
    }
  }
};

$(function() {
  eventSource.addEventListener('weather.forecast', function(event) {
    weather.apply(JSON.parse(event.data));
  });
  requestEvents('weather');
});
