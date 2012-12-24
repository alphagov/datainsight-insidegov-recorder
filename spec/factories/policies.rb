require_relative "../../lib/datamapper_config"
require_relative "../../lib/model/policy"

FactoryGirl.define do

  factory :policy do
    sequence(:slug) { |n| "/slug-#{n}" }
    sequence(:title) { |n| "title #{n}" }
    sequence(:department) { |n| "department #{n}" }
    sequence(:organisations) { |n| "[{'abbreviation':'ABR','name':'organisation #{n}'}]" }
    sequence(:source) { |n| "source #{n}" }
    sequence(:updated_at) { |n| DateTime.parse("2012-11-19T00:#{"%02d" % (n%60)}:00+00:00") }
    sequence(:collected_at) { |n| DateTime.parse("2012-11-19T00:#{"%02d" % (n%60)}:00+00:00") }
  end
end