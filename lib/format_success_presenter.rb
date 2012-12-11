require_relative "response"

class FormatSuccessPresenter

  def present(format_visits)
    sources = format_visits.map { |fv| fv.source }.uniq

    date = format_visits.map { |fv| fv.collected_at }.max
    update_date = format_date(date)

    data = format_visits.map { |fv|
      {
          format: fv.format,
          entries: fv.entries,
          percentage_of_success: fv.successes * 100.0 / fv.entries
      }
    }

    Response.build(data, sources, update_date)
  end

  private
  def format_date(date)
    date.present? ? date.strftime : nil
  end
end