require "data_mapper"
require "datainsight_recorder/base_fields"
require "datainsight_recorder/time_series"
require "json"

class WeeklyReach
  include DataMapper::Resource
  include DataInsight::Recorder::BaseFields
  include DataInsight::Recorder::TimeSeries

  METRICS = %w(visitors)

  property :metric, String, required: true
  property :value, Integer, required: true

  validates_within :metric, set: METRICS
  validates_with_method :validate_time_series_week

  def self.update_from_message(message)
    metric = :visitors
    validate_message(message, metric)
    return if message[:payload][:value][metric].nil?
    query = {
      :metric => metric,
      :start_at => DateTime.parse(message[:payload][:start_at]),
      :end_at => DateTime.parse(message[:payload][:end_at])
    }
    weekly_visitors = WeeklyReach.first(query)
    if weekly_visitors
      logger.info("Update existing record for #{query}")
      weekly_visitors.value = message[:payload][:value][metric]
      weekly_visitors.source = message[:envelope][:collector] # to get around migration
      weekly_visitors.collected_at = message[:envelope][:collected_at]
      weekly_visitors.save
    else
      logger.info("Create new record for #{query}")
      WeeklyReach.create(
        :value => message[:payload][:value][metric],
        :metric => metric,
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

  private

  def validate_value
    if value >= 0
      true
    else
      [false, "Weekly reach value must be a positive integer"]
    end
  end
end
