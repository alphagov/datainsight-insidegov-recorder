class TimeSeriesPresenter
  class Response
    def initialize(response)
      @response = response
    end

    def is_error?
      @response[:response_info][:status] != "ok"
    end

    def to_json
      @response.to_json
    end
  end

  def initialize(id)
    @id = id
  end

  def present(time_series_data)
    if time_series_data.length == 0
      response = {
        response_info: { status: "error" }
      }
    else
      response = {
        response_info: { status: "ok" },
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
    lookup = Hash[time_series_data.map { |item| [item.start_at.to_date, item] }]
    start_at = time_series_data.map(&:start_at).min.to_date
    (start_at..last_sunday_of(Date.today)).step(7).map { |start_at|
      {
        start_at: start_at,
        end_at: start_at + 6,
        value: (lookup[start_at].value if lookup.has_key?(start_at))
      }
    }
  end

  def last_sunday_of(date)
    date - (date.wday == 0 ? 7 : date.wday)
  end
end