require_relative "time_period_presenter"

class ContentEngagementDetailPresenter
  def present(engagement_data)
    ensure_all_values_match(engagement_data, :start_at)
    ensure_all_values_match(engagement_data, :end_at)

    TimePeriodPresenter.new.present(engagement_data) do |each|
      {
        :format => each.format,
        :slug => each.slug,
        :entries => each.entries,
        :successes => each.successes
      }
    end
  end

  private

  def ensure_all_values_match(values, field)
    unique_values = values.map(&field).uniq
    raise "All values do not match for #{field}: #{unique_values}" if unique_values.count > 1
  end
end