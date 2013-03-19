class TimePeriodPresenter
  TIMESTAMP_FORMAT="%Y-%m-%dT%H:%M:%S"

  def start_at(data)
    data.first.start_at
  end

  def end_at(data)
    data.last.end_at
  end

  def sources(data)
    data.map(&:source).uniq
  end

  def updated_at(data)
    data.map(&:collected_at).compact.max
  end

  def present(data, &block)
    raise "Cannot present an empty series" if data.empty?
    build(data, data.map {|item| block.call(item) })
  end

  def build(data, inner_data)
    {
      response_info: {status: "ok"},
      details: {
        start_at:   start_at(data).strftime(TIMESTAMP_FORMAT),
        end_at:     end_at(data).strftime(TIMESTAMP_FORMAT),
        source:     sources(data),
        data:       inner_data
      },
      updated_at: updated_at(data).strftime(TIMESTAMP_FORMAT)
    }
  end
end