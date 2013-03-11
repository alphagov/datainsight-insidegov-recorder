require_relative "../../lib/model/artefact"

FactoryGirl.define do
  factory :artefact do
    sequence(:slug) { |n| "/slug-#{n}" }
    format("policy")
    sequence(:url) { |n| "/government/slug-#{n}" }
    sequence(:title) { |n| "title #{n}" }
    sequence(:organisations) { |n| "[{\"abbreviation\":\"ABR\",\"name\":\"organisation #{n}\"}]" }
    sequence(:source) { |n| "source #{n}" }
    sequence(:artefact_updated_at) { |n| DateTime.parse("2012-11-19T00:#{"%02d" % (n%60)}:00+00:00") }
    sequence(:collected_at) { |n| DateTime.parse("2012-11-19T00:#{"%02d" % (n%60)}:00+00:00") }
  end
end