class ContentEngagementDetailPresenter
  def present(content_engagement_visits)
    ensure_equal(content_engagement_visits.map { |fv| fv.start_at }, :start_at)
    ensure_equal(content_engagement_visits.map { |fv| fv.end_at }, :end_at)

    sources = content_engagement_visits.map { |fv| fv.source }.uniq

    updated_at = content_engagement_visits.map { |fv| fv.collected_at }.max

    {
      response_info: {status: "ok"},
      :details => {
        :start_at => content_engagement_visits.first.start_at.strftime,
        :end_at => content_engagement_visits.first.end_at.strftime,
        :source => sources,
        :data => content_engagement_visits.map { |each|
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

  def ensure_equal(values, field)
    unique_values = values.uniq
    raise "visits have different values for #{field}: #{unique_values}" if unique_values.count > 1
  end
end