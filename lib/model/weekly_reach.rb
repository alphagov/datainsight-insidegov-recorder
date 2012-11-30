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

  private

  def validate_value
    if value >= 0
      true
    else
      [false, "Weekly reach value must be a positive integer"]
    end
  end
end
