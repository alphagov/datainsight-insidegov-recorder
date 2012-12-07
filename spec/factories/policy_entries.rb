require_relative "../../lib/datamapper_config"
require_relative "../../lib/model/policy_entries"

FactoryGirl.define do
  factory :policy_entries do
    sequence(:entries) { |n| n*100000 }
    sequence(:slug) { |n| "/slug-#{n}"}
    sequence(:source) { |n| "source #{n}" }
    sequence(:collected_at) { |n| DateTime.parse("2012-11-19T00:#{"%02d" % (n%60)}:00+00:00") }

    start_at Date.parse("2012-08-06")
    end_at Date.parse("2012-08-12")

    association :policy, factory: :policy
  end
end