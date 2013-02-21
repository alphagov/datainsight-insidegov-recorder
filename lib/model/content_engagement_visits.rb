require_relative "artefact"

class ContentEngagementVisits
  include DataMapper::Resource
  include DataInsight::Recorder::BaseFields
  include DataInsight::Recorder::TimeSeries

  property :format, String, required: true
  property :slug, Text, required: true
  property :entries, Integer, required: true
  property :successes, Integer, required: true

  validates_with_method :entries, method: :is_entries_positive?
  validates_with_method :successes, method: :is_successes_positive?

  attr_reader :artefact

  def self.last_week_visits
    engagement = self.all(start_at: max(:start_at)).first
    results = repository(:default).adapter.query("SELECT artefacts.title, artefacts.url, artefacts.slug, artefacts.format, engagement.start_at, engagement.end_at, engagement.entries, engagement.successes
FROM artefacts
LEFT JOIN content_engagement_visits AS engagement ON (start_at='#{engagement.start_at}' AND engagement.slug=artefacts.slug AND engagement.format=artefacts.format)
ORDER BY engagement.entries DESC"
    )
    results.map do |result|
      OpenStruct.new(
        format: result.format,
        slug: result.slug,
        entries: result.entries || 0,
        successes: result.successes || 0,
        start_at: engagement.start_at,
        end_at: engagement.end_at,
        collected_at: engagement.collected_at,
        artefact: OpenStruct.new(
          title: result.title,
          url: result.url
        )
      )
    end
  end

  def self.update_from_message(message)
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

  private
  attr_writer :artefact


  def is_entries_positive?
    is_positive?(entries)
  end

  def is_successes_positive?
    is_positive?(successes)
  end

  def is_positive?(value)
    return [false, "It must be numeric"] unless value.is_a?(Numeric)
    (value >= 0) ? true : [false, "It must be greater than or equal to 0"]
  end
end