class ContentEngagementDetailPresenter
  def present(engagement_data)
    ensure_all_values_match(engagement_data, :start_at)
    ensure_all_values_match(engagement_data, :end_at)

    start_at   = engagement_data.first.start_at.strftime
    end_at     = engagement_data.first.end_at.strftime
    sources    = engagement_data.map(&:source).uniq
    updated_at = engagement_data.map(&:collected_at).max

    {
      response_info: {status: "ok"},
      :details => {
        :start_at => start_at,
        :end_at => end_at,
        :source => sources,
        :data => engagement_data.map { |each|
          {
            :format => each.format,
            :slug => each.slug,
            :entries => each.entries,
            :successes => each.successes
          }
        }
      },
      :updated_at => updated_at.strftime,
    }
  end

  private

  def ensure_all_values_match(values, field)
    unique_values = values.map(&field).uniq
    raise "All values do not match for #{field}: #{unique_values}" if unique_values.count > 1
  end
end