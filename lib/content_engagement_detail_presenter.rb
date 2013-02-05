class ContentEngagementDetailPresenter
  def present(content_engagement_visits)
    sources = content_engagement_visits.map { |fv| fv.source }.uniq

    updated_at = content_engagement_visits.map { |fv| fv.collected_at }.max

    {
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
end