require_relative "../../lib/datamapper_config"
require_relative "../../lib/model/weekly_reach"

FactoryGirl.define do
  factory :model, class: WeeklyReach do
    start_at Date.parse("2012-08-06")
    end_at Date.parse("2012-08-12")
    value 500
    metric "visitors"
    collected_at DateTime.now
    source "Google Analytics"
  end
end