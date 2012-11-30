require "bundler/setup"
Bundler.require(:default, :exposer)

require_relative "model/weekly_reach"
require_relative "datamapper_config"
require_relative "initializers"

helpers Datainsight::Logging::Helpers

use Airbrake::Rack
enable :raise_errors

configure do
  enable :logging
  unless test?
    Datainsight::Logging.configure(:type => :exposer)
    DataMapperConfig.configure
  end
end

get "/visitors/weekly" do
  WeeklyReach.json_representation
end
