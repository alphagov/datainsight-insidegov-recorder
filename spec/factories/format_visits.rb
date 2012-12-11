require_relative "../../lib/datamapper_config"
require_relative "../../lib/model/policy"

FactoryGirl.define do

  factory :format_visits do
    format "default-format"
    entries 0
    successes 0
    source "default source"
    start_at DateTime.new(1970, 1, 1, 12, 42, 0)
    end_at DateTime.new(1970, 1, 1, 12, 42, 0)
    collected_at DateTime.new(1970, 1, 1, 12, 42, 0)
  end
end