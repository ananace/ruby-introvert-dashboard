require 'introvert-dashboard'

IntrovertDashboard::Config.load 'config.yml' if File.exist? 'config.yml'

IntrovertDashboard::Components.constants.each do |const|
  klass = IntrovertDashboard::Components.const_get const
  next unless klass.available?

  puts "Mapping /api/#{klass.api_name} to #{klass}"
  map "/api/#{klass.api_name}" do
    run klass
  end
end

map '/' do
  run IntrovertDashboard::Server
end

