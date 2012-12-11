require "bundler/setup"
Bundler.require(:default, :exposer)

require_relative "model/weekly_reach"
require_relative "model/policy_entries"
require_relative "model/format_visits"
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

get "/entries/weekly/policies" do
  content_type :json
  top_five_policies = PolicyEntries.top_5

  return 503 unless top_five_policies.length == 5

  {
    response_info: {status: "ok"},
    details: {
      data: top_five_policies.map { |policy_entry|
        {
          entries: policy_entry.entries,
          policy: {
            title: "missing",
            web_url: "https://www.gov.uk/government/policies/#{policy_entry.slug}",
            updated_at: "missing",
            department: "missing"
          }
        }
      }
    },
    updated_at: top_five_policies.map { |policy_entry| [policy_entry.collected_at] }.flatten.max

  }.to_json

end

get "/visitors/weekly" do
  content_type :json
  response = DateSeriesPresenter.weekly("/visitors/weekly").present(WeeklyReach.last_six_months)

  [response.is_error? ? 500 : 200, response.to_json]
end

get "/format-success/weekly" do
  format_visits = FormatVisits.all

  content_type :json
  {
      response_info: {status: "ok"},
      details: {
        source: format_visits.map { |fv| fv.source }.uniq,
        data: format_visits.map { |fv|
          {
              format: fv.format,
              entries: fv.entries,
              percentage_of_success: fv.successes * 100.0 / fv.entries
          }
        }
      }
  }.to_json
end
