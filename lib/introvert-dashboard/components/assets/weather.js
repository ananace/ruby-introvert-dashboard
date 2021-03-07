var weather = {
  apply: function(input) {
    //$('#weatherTitle').attr('title', 'Updated ' + Date());

    var days = ['now','today','tomorrow'];
    const hours = new Date().getHours();
    // const isDayTime = hours > 6 && hours < 20;
    var i;
    for (i in days) {
      const day = days[i];
      var data = undefined;
      var curdata = undefined;
      if (day == 'now') {
        data = input['today'];
        curdata = data.by_hour[0];
      } else {
        data = input[day];
        curdata = data.average;
      }

      const id = "weather" + day.charAt(0).toUpperCase() + day.substring(1);
      var title = '<i style="font-size: 32pt; width: 4rem" class="text-center wi '+curdata.symbol+' mr-2"></i>\n';
      if (day === 'now') {
        title +=  '<span class="align-top d-inline-flex flex-column">\n'+
                  '  <span style="size: 25pt;">'+curdata.temperature+'<i class="wi wi-celsius"></i></span>\n';
      } else {
        title +=  '<span class="align-top d-inline-flex flex-column">\n'+
                  '  <span>'+curdata.temperature+'<i class="wi wi-celsius"></i></span>\n'+
                  '  <span class="text-white-50" style="font-size:9pt">'+data.average_day.temperature+'<i class="wi wi-celsius mr-1"></i>'+data.average_night.temperature+'<i class="wi wi-celsius"></i><br/></span>';
      }
      title = title +    '</span>';
      $('#' + id + ' .card-title').html(title);

      var subtitle = '<i class="wi wi-wind from-'+Math.round(curdata.wind.dir)+'-deg mr-1"></i>'+curdata.wind.speed+'<small>m/s</small>&nbsp;\n'+
                     '<i class="wi wi-humidity mr-1"></i>'+curdata.humidity+'<small>%</small>';

      if (curdata.precipitation.category_id != 0) {
        const pmax = Math.round(curdata.precipitation.max * 10) / 10;
        const pmin = Math.round(curdata.precipitation.min * 10) / 10;

        subtitle += '<br/>\n<i class="wi wi-cloud-down mr-1 align-top"></i><small class="align-top" style="font-size:70%">'+pmin+' - '+pmax+'<small class="align-baseline">mm/h</small> '+curdata.precipitation.category+'</small>';
      }
      $('#' + id + ' .card-subtitle').html(subtitle);
    }
  }
};

$(function() {
  eventSource.addEventListener('weather.forecast', function(event) {
    weather.apply(JSON.parse(event.data));
  });
  requestEvents('weather');
});
