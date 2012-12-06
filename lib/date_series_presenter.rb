require_relative "date_utils"

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
      response = {
        response_info: {status: "ok"},
        id: @id,
        web_url: "",
        details: {
          source: time_series_data.map(&:source).uniq,
          data: add_missing_datapoints(time_series_data)
        },
        updated_at: time_series_data.map(&:collected_at).max
      }
    end
    Response.new(response)
  end

  def add_missing_datapoints(time_series_data)
    lookup = Hash[time_series_data.map { |item| [item.start_at, item] }]
    start_at = time_series_data.map(&:start_at).min
    if start_at != start_at.to_date
      raise "Periods must start at midnight; received #{start_at}."
    end
    (start_at..end_date_for(Date.today)).step(@days_to_step).reject {|start_at|
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
    if (end_at - start_at) != @days_to_step
      raise "Invalid period, expecting #@days_to_step but received #{(end_at - start_at).to_f}"
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