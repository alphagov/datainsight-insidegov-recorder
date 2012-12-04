require_relative "../../lib/datamapper_config"
require_relative "../../lib/model/policy_visits"

FactoryGirl.define do
  factory :policy_visits do
    sequence(:visits) { |n| n*100000 }
    sequence(:slug) { |n| "/slug-#{n}"}
    association :policy, factory: :policy
  end
end