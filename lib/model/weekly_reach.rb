require "data_mapper"
require "datainsight_recorder/base_fields"
require "datainsight_recorder/time_series"

class WeeklyReach
  include DataMapper::Resource
  include DataInsight::Recorder::BaseFields
  include DataInsight::Recorder::TimeSeries

  property :value, Integer, required: true

  def self.retrieve(start_at, end_at)
    WeeklyReach.all(
      :start_at.gte => start_at,
      :end_at.lte => end_at,
      :order => [ :start_at.asc ]
    )
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