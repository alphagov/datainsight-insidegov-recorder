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
    results = repository(:default).adapter.select(
      "select * from content_engagement_visits c
       right join artefacts a
       on (c.slug = a.slug
         and c.format = a.format
         and c.start_at = (select max(start_at) from content_engagement_visits))
       where (
        a.disabled = false
        and (a.format != 'news'
          or a.format = 'news' and (c.entries > 1000 or a.artefact_updated_at > ?)))",
      (DateTime.now << 2))

    start_at = results.map { |each| each.start_at }.compact.first
    end_at = results.map { |each| each.end_at }.compact.first
    
    results.map { |each|
      ContentEngagementVisits.new(
        :format => each.format,
        :slug => each.slug,
        :entries => (each.entries or 0),
        :successes => (each.successes or 0),
        :start_at => start_at,
        :end_at => end_at,
        :collected_at => each.collected_at,
        :source => each.source
      ).tap { |engagement|
        engagement.send(
          :artefact=,
            Artefact.new(
              :format => each.format,
              :slug => each.slug,
              :title => each.title,
              :url => each.url,
              :organisations => each.organisations,
              :artefact_updated_at => each.artefact_updated_at,
              :disabled => each.disabled,
              :source => each.source
            ))
      }
    }
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