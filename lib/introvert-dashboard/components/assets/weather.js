function updateWeather() {
  axios.get('/api/weather')
    .then(function(resp) {
      var days = ['today','tomorrow'];
      const hours = new Date().getHours();
      const isDayTime = hours > 6 && hours < 20;
      for (i in days) {
        var day = days[i];
        var data = resp.data[day];
        var curdata = (day == 'today') ? data.by_hour[0] : data.average;

        var id = "weather" + day.charAt(0).toUpperCase() + day.substring(1);
        var title = '<i style="font-size: 32pt; width: 4rem" class="text-center wi '+curdata.symbol+' mr-2"></i>\n'+
                    '<span class="align-top d-inline-flex flex-column">\n'+
                    '  <span>'+curdata.temperature+'<i class="wi wi-celsius"></i></span>\n'+
                    '  <span class="text-white-50" style="font-size:9pt">'+data.average_day.temperature+'<i class="wi wi-celsius mr-1"></i>'+data.average_night.temperature+'<i class="wi wi-celsius"></i><br/></span>'+
                    '</span>';
        $('#' + id + ' .card-title').html(title);

        var subtitle = '<i class="wi wi-wind from-'+Math.round(curdata.wind.dir)+'-deg mr-1"></i>'+curdata.wind.speed+'<small>m/s</small>&nbsp;\n'+
                       '<i class="wi wi-humidity mr-1"></i>'+curdata.humidity+'<small>%</small>';

        if (curdata.precipitation.category_id != 0) {
          subtitle += '<br/>\n<i class="wi wi-cloud-down mr-1 align-top"></i><small class="align-top" style="font-size:70%">'+curdata.precipitation.min+' - '+curdata.precipitation.max+'<small>mm</small> '+curdata.precipitation.category+'</small>';
        }
        $('#' + id + ' .card-subtitle').html(subtitle);
      }
    });

  setTimeout(updateWeather, 30*60*1000);
}

$(function() { updateWeather(); });
