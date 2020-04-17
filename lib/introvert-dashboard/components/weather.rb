# frozen_string_literal: true

class Time
  def night?
    !((6...21).include? hour)
  end

  def today?
    day == Time.now.day
  end
end

module IntrovertDashboard::Components
  class Weather < IntrovertDashboard::BaseComponent
    API_HOST = 'opendata-download-metfcst.smhi.se'
    API_CATEGORY = 'pmp3g'
    API_VERSION = '2'

    WEATHER_SYMBOLS_DAY = [
      nil,
      'wi-day-sunny', # Clear sky
      'wi-day-sunny-overcast', # Nearly clear sky
      'wi-day-cloudy', # Variable cloudiness
      'wi-day-cloudy', # Halfclear sky
      'wi-cloud', # Cloudy sky
      'wi-cloudy', # Overcast
      'wi-day-fog', # Fog
      'wi-day-sprinkle', # Light rain showers
      'wi-day-showers', # Moderate rain showers
      'wi-day-rain', # Heavy rain showers
      'wi-day-thunderstorm', # Thunderstorm
      'wi-day-sleet', # Light sleet showers
      'wi-day-sleet', # Moderate sleet showers
      'wi-day-sleet', # Heavy sleet showers
      'wi-day-snow', # Light snow showers
      'wi-day-snow', # Moderate snow showers
      'wi-day-snow', # Heavy snow showers
      'wi-sprinkle', # Light rain
      'wi-showers', # Moderate rain
      'wi-rain', # Heavy rain
      'wi-day-lightning', # Thunder
      'wi-sleet', # Light sleet
      'wi-sleet', # Moderate sleet
      'wi-sleet', # Heavy sleet
      'wi-snow', # Light snowfall
      'wi-snow', # Moderate snowfall
      'wi-snow', # Heavy snowfall
    ]
    WEATHER_SYMBOLS_NIGHT = [
      nil,
      'wi-night-clear', # Clear sky
      'wi-night-alt-partly-cloudy', # Nearly clear sky
      'wi-night-alt-cloudy', # Variable cloudiness
      'wi-night-alt-cloudy', # Halfclear sky
      'wi-cloud', # Cloudy sky
      'wi-cloudy', # Overcast
      'wi-night-fog', # Fog
      'wi-night-alt-sprinkle', # Light rain showers
      'wi-night-alt-showers', # Moderate rain showers
      'wi-night-alt-rain', # Heavy rain showers
      'wi-night-alt-thunderstorm', # Thunderstorm
      'wi-night-alt-sleet', # Light sleet showers
      'wi-night-alt-sleet', # Moderate sleet showers
      'wi-night-alt-sleet', # Heavy sleet showers
      'wi-night-alt-snow', # Light snow showers
      'wi-night-alt-snow', # Moderate snow showers
      'wi-night-alt-snow', # Heavy snow showers
      'wi-sprinkle', # Light rain
      'wi-showers', # Moderate rain
      'wi-rain', # Heavy rain
      'wi-night-alt-lightning', # Thunder
      'wi-sleet', # Light sleet
      'wi-sleet', # Moderate sleet
      'wi-sleet', # Heavy sleet
      'wi-snow', # Light snowfall
      'wi-snow', # Moderate snowfall
      'wi-snow', # Heavy snowfall
    ]

    PRECIP_CATEGORIES = [
      :none,
      :snow,
      :mix,
      :rain,
      :drizzle,
      :freezing_rain,
      :freezing_drizzle
    ]

    def get_forecast(lat, lon)
      uri = URI("https://#{API_HOST}/").tap do |u|
        u.path = "/api/category/#{API_CATEGORY}/version/#{API_VERSION}/geotype/point/lon/#{lon}/lat/#{lat}/data.json"
      end
      [JSON.parse(Net::HTTP.get(uri), symbolize_names: true)].map do |resp|
        today = { by_hour: [] }
        tomorrow = { by_hour: [] }

        resp[:timeSeries].each do |point|
          time = Time.parse(point[:validTime])
          time.localtime
          next if time.day > Time.now.day + 1

          target = time.today? ? today : tomorrow
          
          target[:by_hour] << {
            time: time,
            pressure: point[:parameters].find { |p| p[:name] == 'msl' }[:values].first,
            temperature: point[:parameters].find { |p| p[:name] == 't' }[:values].first,
            wind: {
              dir: point[:parameters].find { |p| p[:name] == 'wd' }[:values].first,
              speed: point[:parameters].find { |p| p[:name] == 'ws' }[:values].first,
              gust_speed: point[:parameters].find { |p| p[:name] == 'gust' }[:values].first,
            },
            precipitation: {
              min: point[:parameters].find { |p| p[:name] == 'pmin' }[:values].first,
              max: point[:parameters].find { |p| p[:name] == 'pmax' }[:values].first,
              category: point[:parameters].find { |p| p[:name] == 'pcat' }[:values].first,
            },
            humidity: point[:parameters].find { |p| p[:name] == 'r' }[:values].first,
            symbol: point[:parameters].find { |p| p[:name] == 'Wsymb2' }[:values].first,
          }
        end

        [today,tomorrow].each do |source|
          [:average, :average_day, :average_night].each do |target|
            avg = source[target] = { pressure: 0, temperature: 0, wind: { dir: 0, speed: 0, gust_speed: 0 }, precipitation: { min: 0, max: 0, category: nil }, humidity: 0, symbol: nil }

            overall = target == :average
            if overall
              points = source[:by_hour]
            else
              night = target == :average_night
              points = source[:by_hour].select { |p| p[:time].night? == night }
            end

            count = 0
            points.each do |h|
              count += 1
              %i[pressure temperature humidity].each { |s| avg[s] += h[s] }
              %i[dir speed].each { |s| avg[:wind][s] += h[:wind][s] }
              %i[min max].each { |s| avg[:precipitation][s] += h[:precipitation][s] }
            end

            if count > 0
              %i[pressure temperature humidity].each { |s| avg[s] = (avg[s] / count).round(2) }
              %i[dir speed].each { |s| avg[:wind][s] = (avg[:wind][s] / count).round(2) }
              %i[min max].each { |s| avg[:precipitation][s] = (avg[:precipitation][s] / count).round(2) }
            end
            avg[:precipitation][:category] = source[:by_hour].group_by{|i| i.dig :precipitation, :category }.max{|x,y| x[1].length <=> y[1].length}&.first
            avg[:symbol] = source[:by_hour].group_by{|i| i.dig :symbol}.max{|x,y| x[1].length <=> y[1].length}&.first
          end
        end

        [today,tomorrow].each do |source|
          source[:by_hour].each do |h|
            next unless h[:symbol].is_a? Numeric

            symbols = h[:time].night? ? WEATHER_SYMBOLS_NIGHT : WEATHER_SYMBOLS_DAY
            h[:symbol] = symbols[h[:symbol]]
          end
          %i[average average_day average_night].each do |avg|
            symbols = avg == :average_night ? WEATHER_SYMBOLS_NIGHT : WEATHER_SYMBOLS_DAY
            next if source.dig(avg, :symbol).nil?
            next unless source.dig(avg, :symbol).is_a? Numeric

            source[avg][:symbol] = symbols[source[avg][:symbol]]
          end
        end

        { today: today, tomorrow: tomorrow }
      end.first
    end

    def render_card(doc)
      doc.div.card.weather! style: 'width: 235px', 'data-order': 0  do
        doc.div class: 'card-header' do
          doc.nav do
            doc.ul.nav class: 'nav-xs nav-tabs card-header-tabs', role: :tablist do
              doc.li class: 'nav-item mr-auto' do
                doc.text 'Weather'
              end
              doc.li class: 'nav-item' do
                doc.a.active.weatherTodayTab! class: 'nav-link', href: '#weatherToday', role: :tab, 'data-toggle': :tab, 'aria-controls': 'weatherToday', 'aria-selected': true do
                  doc.text 'Today'
                end
              end
              doc.li class: 'nav-item' do
                doc.a.weatherTomorrowTab! class: 'nav-link', href: '#weatherTomorrow', role: :tab, 'data-toggle': :tab, 'aria-controls': 'weatherTomorrow', 'aria-selected': false do
                  doc.text 'Tomorrow'
                end
              end
            end
          end
        end

        doc.div class: 'card-body tab-content' do
          doc.div.show.active.weatherToday! class: 'tab-pane', role: :tabpanel, 'aria-labelledby': 'weatherTodayTab' do
            doc.h5 class: 'card-title'
            doc.h5 class: 'card-subtitle text-muted'
            doc.p class: 'card-text'
          end
          doc.div.weatherTomorrow! class: 'tab-pane', role: :tabpanel, 'aria-labelledby': 'weatherTomorrowTab' do
            doc.h5 class: 'card-title'
            doc.h5 class: 'card-subtitle text-muted'
            doc.p class: 'card-text'
          end
        end
      end

      doc.script do
        doc.text <<~JS
        function updateWeather() {
          axios.get('/api/weather')
            .then(function(resp) {
              var days = ['today','tomorrow'];
              const hours = new Date().getHours();
              const isDayTime = hours > 6 && hours < 20;
              for (i in days) {
                var day = days[i];
                var data = resp.data[day];
                var average = (day == 'tomorrow' || isDayTime) ? 'average_day' : 'average_night';
                var curdata = ((day == 'today') ? data.by_hour[0] : data[average]) || data.average;

                var id = "weather" + day.charAt(0).toUpperCase() + day.substring(1);
                var title = '<i style="font-size: 32pt; width: 4rem" class="text-center wi ' + curdata.symbol + ' mr-2"></i><span class="align-top d-inline-flex flex-column"><span>' + curdata.temperature + '<i class="wi wi-celsius"></i></span><span class="text-white-50" style="font-size:9pt">' + data.average_day.temperature + '<i class="wi wi-celsius"></i> ' + data.average_night.temperature + '<i class="wi wi-celsius"></i></span></span>';
                $('#' + id + ' .card-title').html(title);

                var subtitle = '<i class="wi wi-wind towards-' + Math.round(curdata.wind.dir) + '-deg mr-1"></i>' + data[average].wind.speed + '<small>m/s</small>&nbsp;<i class="wi wi-humidity mr-1"></i>' + curdata.humidity + '<small>%</small>';
                $('#' + id + ' .card-subtitle').html(subtitle);
              }
            });

          setTimeout(updateWeather, 30*60*1000);
        }

        $(function() { updateWeather(); });
        JS
      end
    end

    get '/' do
      get_forecast(58.1971, 15.0538).to_json
    end
  end
end


