require "bundler/setup"
Bundler.require(:default, :exposer)

require "datainsight_logging"
require "datainsight_recorder/datamapper_config"

require_relative "model/weekly_reach"
require_relative "model/policy_entries"
require_relative "model/format_visits"
require_relative "model/content_engagement_visits"
require_relative "presenter/date_series_presenter"
require_relative "presenter/content_engagement_presenter"
require_relative "presenter/content_engagement_detail_presenter"
require_relative "presenter/policy_presenter"
require_relative "initializers"

helpers Datainsight::Logging::Helpers

use Airbrake::Rack
enable :raise_errors

SUPPORTED_FORMATS = %w(news policy)

configure do
  enable :logging
  unless test?
    Datainsight::Logging.configure(:type => :exposer)
    DataInsight::Recorder::DataMapperConfig.configure
  end
end

get "/entries/weekly/policies" do
  content_type :json
  top_ten_policies = PolicyEntries.top_last_week(10)

  return 503 unless top_ten_policies.length == 10

  response = PolicyPresenter.new.present(top_ten_policies)

  content_type :json
  response.to_json
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
  response = ContentEngagementPresenter.new.present(format_visits)

  content_type :json
  response.to_json
end

get "/content-engagement-detail/weekly" do
  content_engagement_visits = ContentEngagementVisits.last_week_visits(SUPPORTED_FORMATS)
  return 500 if content_engagement_visits.empty?

  response = ContentEngagementDetailPresenter.new.present(content_engagement_visits)

  content_type :json
  response.to_json
end