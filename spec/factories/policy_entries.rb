require_relative "../../lib/model/policy_entries"

FactoryGirl.define do
  factory :policy_entries, :parent => :policy_entries_without_policy do
    after(:build) do |policy_entries, evaluator|
      if policy_entries.policy.nil?
        policy_entries.policy =
                        FactoryGirl.create(:artefact, :slug => policy_entries.slug, :format => "policy")
      end
    end
  end

  factory :policy_entries_without_policy, :class => PolicyEntries do
    sequence(:entries) { |n| n*100000 }
    sequence(:slug) { |n| "/slug-#{n}"}
    sequence(:source) { |n| "source #{n}" }
    sequence(:collected_at) { |n| DateTime.parse("2012-11-19T00:#{"%02d" % (n%60)}:00+00:00") }

    start_at DateTime.parse("2012-08-06T00:00:00+01:00")
    end_at DateTime.parse("2012-08-13T00:00:00+01:00")
  end
end