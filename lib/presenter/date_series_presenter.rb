require_relative "../date_utils"
require_relative "time_period_presenter"

class DateSeriesPresenter
  class Response
    def initialize(response)
      @response = response
    end

    def is_error?
      @response[:response_info][:status] != "ok"
    end

    def raw
      @response
    end

    def limit(limit)
      if limit < @response[:details][:data].length
        @response[:details][:data] = @response[:details][:data][0-limit..-1]
      end
      self
    end

    def to_json
      @response.to_json
    end
  end

  def self.daily(id)
    return new(id, 1, :daily)
  end

  def self.weekly(id)
    return new(id, 7, :weekly)
  end

  private_class_method :new

  def initialize(id, days_to_step, period)
    @id = id
    @days_to_step = days_to_step
    @period = period
  end

  def present(time_series_data)
    if time_series_data.length == 0
      response = {
        response_info: {status: "error"}
      }
    else
      response = TimePeriodPresenter.new.build(
        time_series_data,
        add_missing_datapoints(time_series_data)
      )
    end
    Response.new(response)
  end

  def midnight?(datetime)
    datetime.hour == 0 && datetime.minute == 0 && datetime.second == 0 && datetime.second_fraction == 0
  end

  def add_missing_datapoints(time_series_data)
    lookup = Hash[time_series_data.map { |item| [item.start_at, item] }]
    start_at = time_series_data.map(&:start_at).min
    if !midnight?(start_at)
      raise "Periods must start at midnight; received #{start_at}."
    end
    (start_at..end_date_for(Date.today)).step(@days_to_step).reject { |start_at|
      # Do not add null values for the last data point if we're on the same day
      (Date.today == start_at + @days_to_step) and !lookup.has_key?(start_at)
    }.map do |start_at|
      value = lookup[start_at].value if lookup.has_key?(start_at)
      validate_period(start_at, lookup[start_at].end_at) unless value.nil?
      {
        start_at: start_at.to_date,
        end_at: start_at.to_date + @days_to_step - 1,
        value: value
      }
    end
  end

  private
  def validate_period(start_at, end_at)
    if (end_at.to_date - start_at.to_date) != @days_to_step
      raise "Invalid period, expecting #{@days_to_step} days difference,
            but period was: #{{start_at: start_at, end_at: end_at}}"
    end
  end

  def end_date_for(today)
    case @period
      when :daily
        today - 1
      when :weekly
        DateUtils.last_sunday_for(today) - 6
      else
        raise "Invalid period #@period"
    end
  end
end