
class ContentEngagementVisits
  include DataMapper::Resource

  property :format, String, required: true
  property :slug, Text, required: true
  property :entries, Integer, required: true
  property :successes, Integer, required: true
end