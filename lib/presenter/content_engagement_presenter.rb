require_relative "time_period_presenter"

class ContentEngagementPresenter

  def present(format_visits)
    TimePeriodPresenter.new.present(format_visits) do |each|
      {
        format:   each.format,
        entries:  each.entries,
        successes: each.successes,
        percentage_of_success: percentage_of_success(each)
      }
    end
  end

  private

  def percentage_of_success(each)
    (each.entries == 0 ? 0 : each.successes * 100.0 / each.entries)
  end
end