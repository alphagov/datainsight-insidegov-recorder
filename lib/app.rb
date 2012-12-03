require "bundler/setup"
Bundler.require(:default, :exposer)

require_relative "model/weekly_reach"
require_relative "date_series_presenter"
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
  response = DateSeriesPresenter.new("/visitors/weekly").present(WeeklyReach.all)

  [response.is_error? ? 500 : 200, response.to_json]
end
