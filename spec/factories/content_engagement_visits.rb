FactoryGirl.define do
  factory :content_engagement_visits do
    format "guide"
    slug "apply-for-visa"
    entries 10000
    successes 5000
  end
end