require_relative "time_period_presenter"

class ContentEngagementDetailPresenter
  def present(engagement_data)
    ensure_all_values_match(engagement_data, :start_at)
    ensure_all_values_match(engagement_data, :end_at)

    TimePeriodPresenter.new.present(engagement_data) do |each|
      {
        :format => each.format,
        :slug => each.slug,
        :entries => each.entries < SIGNIFICANCE_THRESHOLD ? nil : each.entries,
        :successes => each.entries < SIGNIFICANCE_THRESHOLD ? nil : each.successes,
        :title => each.artefact.title,
        :url => each.artefact.url,
      }
    end
  end

  private

  SIGNIFICANCE_THRESHOLD = 1000

  def ensure_all_values_match(values, field)
    unique_values = values.map(&field).uniq
    raise "All values do not match for #{field}: #{unique_values}" if unique_values.count > 1
  end
end