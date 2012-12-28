require "bundler/setup"
Bundler.require(:default, :exposer)

require_relative "model/weekly_reach"
require_relative "model/policy_entries"
require_relative "model/format_visits"
require_relative "date_series_presenter"
require_relative "format_success_presenter"
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
  top_ten_policies = PolicyEntries.top(10)

  return 503 unless top_ten_policies.length == 10

  {
    response_info: {status: "ok"},
    details: {
      data: top_ten_policies.map { |policy_entry|
        return 503 unless policy_entry.policy
        {
          entries: policy_entry.entries,
          policy: {
            title: policy_entry.policy.title,
            web_url: "https://www.gov.uk/government/policies/#{policy_entry.slug}",
            updated_at: policy_entry.policy.policy_updated_at,
            organisations: JSON.parse(policy_entry.policy.organisations)
          }
        }
      }
    },
    updated_at: top_ten_policies.map { |policy_entry| [policy_entry.collected_at] }.flatten.max

  }.to_json

end

get "/visitors/weekly" do
  content_type :json
  response = DateSeriesPresenter.weekly("/visitors/weekly")
                                .present(WeeklyReach.last_six_months)

  unless request[:limit].nil?
    response.limit(request[:limit].to_i)
  end

  [response.is_error? ? 500 : 200, response.to_json]
end

get "/format-success/weekly" do
  format_visits = FormatVisits.last_week_visits
  response = FormatSuccessPresenter.new.present(format_visits)

  content_type :json
  response.to_json
end
