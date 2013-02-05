FactoryGirl.define do
  factory :content_engagement_visits do
    format "guide"
    slug "apply-for-visa"
    entries 10000
    successes 5000
    start_at DateTime.new(2013, 1, 13, 0, 0, 0)
    end_at DateTime.new(2013, 1, 20, 0, 0, 0)
    collected_at DateTime.new(2013, 1, 21, 0, 0, 0)
    source "Google Analytics"
  end
end