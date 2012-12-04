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

get "/visits/weekly/policies" do
  content_type :json

  the_data = PolicyVisits.top_5

  return 503 unless the_data.length == 5

  {
      response_info: {status: "ok"},
      details: {
          data: the_data.map { |pv|
            {
                visits: pv.visits,
                policy: {
                    title: pv.policy.title,
                    web_url: "https://www.gov.uk#{pv.policy.slug}",
                    updated_at: pv.policy.updated_at,
                    department: pv.policy.department
                }
            }
          }
      }
  }.to_json

end

get "/visitors/weekly" do
  content_type :json
  response = DateSeriesPresenter.weekly("/visitors/weekly").present(WeeklyReach.all)

  [response.is_error? ? 500 : 200, response.to_json]
end
