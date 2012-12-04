require_relative "../../lib/datamapper_config"
require_relative "../../lib/model/policy_visits"

FactoryGirl.define do
  factory :policy_visits do
    sequence(:visits) { |n| n*100000 }
    sequence(:slug) { |n| "/slug-#{n}"}
    sequence(:source) { |n| "source #{n}" }
    sequence(:collected_at) { |n| DateTime.parse("2012-11-19T00:#{"%02d" % (n%60)}:00+00:00") }
    association :policy, factory: :policy
  end
end