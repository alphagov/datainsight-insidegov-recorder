
class ContentEngagementVisits
  include DataMapper::Resource
  include DataInsight::Recorder::BaseFields
  include DataInsight::Recorder::TimeSeries

  property :format, String, required: true
  property :slug, Text, required: true
  property :entries, Integer, required: true
  property :successes, Integer, required: true

  def self.last_week_visits
    ContentEngagementVisits.all(start_at: max(:start_at))
  end

  def self.update_from_message(message)
    validate_message(message, :entries)
    return if message[:payload][:value][:entries].nil?
    message[:payload][:value][:slug] = message[:payload][:value][:slug].downcase
    query = {
      :start_at => DateTime.parse(message[:payload][:start_at]),
      :end_at => DateTime.parse(message[:payload][:end_at]),
      :slug => message[:payload][:value][:slug],
      :source => message[:envelope][:collector],
      :format => message[:payload][:value][:format],
    }
    content_engagement_visits = ContentEngagementVisits.first(query)
    if content_engagement_visits
      logger.info("Update existing record for #{query}")
      content_engagement_visits.slug = message[:payload][:value][:slug]
      content_engagement_visits.entries = message[:payload][:value][:entries]
      content_engagement_visits.successes = message[:payload][:value][:successes]
      content_engagement_visits.format = message[:payload][:value][:format]
      content_engagement_visits.collected_at = DateTime.parse(message[:envelope][:collected_at])
      content_engagement_visits.save
    else
      logger.info("Create new record for #{query}")
      ContentEngagementVisits.create(
        :slug => message[:payload][:value][:slug],
        :entries => message[:payload][:value][:entries],
        :successes => message[:payload][:value][:successes],
        :format => message[:payload][:value][:format],
        :start_at => DateTime.parse(message[:payload][:start_at]),
        :end_at => DateTime.parse(message[:payload][:end_at]),
        :collected_at => DateTime.parse(message[:envelope][:collected_at]),
        :source => message[:envelope][:collector]
      )
    end
  end

  def self.validate_message(message, metric)
    raise "No value provided in message payload: #{message.inspect}" unless message[:payload].has_key? :value
    raise "No metric value provided in message payload: #{message.inspect} #{metric}" unless message[:payload][:value].has_key? metric
  end

end