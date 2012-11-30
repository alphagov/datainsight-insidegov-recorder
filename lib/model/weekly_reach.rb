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

  def self.json_representation
    all_the_things = WeeklyReach.all
    return if all_the_things.length == 0

    {
      response_info: { status: "ok" },
      id: "/visitors/weekly",
      web_url: "",
      details: {
        source: all_the_things.map(&:source).uniq,
        data: add_missing_datapoints(all_the_things)
      },
      updated_at: all_the_things.map(&:collected_at).max
    }.to_json
  end

  def self.add_missing_datapoints(visitors)
    lookup = Hash[visitors.map { |item| [item.start_at.to_date, item] }]
    start_at = visitors.map(&:start_at).min.to_date
    (start_at..last_sunday_of(Date.today)).step(7).map { |start_at|
      {
        start_at: start_at,
        end_at: start_at + 6,
        value: (lookup[start_at].value if lookup.has_key?(start_at))
      }
    }
  end

  def self.last_sunday_of(date)
    date - (date.wday == 0 ? 7 : date.wday)
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
