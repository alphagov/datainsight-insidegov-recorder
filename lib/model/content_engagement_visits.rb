require_relative "artefact"

class ContentEngagementVisits
  include DataMapper::Resource
  include DataInsight::Recorder::BaseFields
  include DataInsight::Recorder::TimeSeries

  property :format, String, required: true
  property :slug, Text, lazy: false, required: true
  property :entries, Integer, required: true
  property :successes, Integer, required: true

  validates_with_method :entries, method: :is_entries_positive?
  validates_with_method :successes, method: :is_successes_positive?

  attr_reader :artefact

  def self.last_week_visits
    visits = ContentEngagementVisits.all(start_at: max(:start_at))
    visits_hash = Hash[visits.map { |visits| [[visits.format, visits.slug], visits] }]

    Artefact.all(disabled: false).map do |artefact|
      visits_for(artefact, visits_hash).tap { |visits| visits.send(:artefact=, artefact) }
    end
  end

  def self.visits_for(artefact, visits)
    artefact_visits = visits[[artefact.format, artefact.slug]]
    artefact_visits || ContentEngagementVisits.new(
      entries: 0,
      successes: 0,
      slug: artefact.slug,
      format: artefact.format,
      start_at: visits.values.first[:start_at],
      end_at: visits.values.first[:end_at]
    )
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