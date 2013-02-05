class ContentEngagementDetailPresenter
  def present(content_engagement_visits)
    {
      :details => {
        :data => content_engagement_visits.map { |each|
          {
            :format => each.format,
            :slug => each.slug,
            :entries => each.entries,
            :successes => each.successes
          }
        }
      }
    }
  end
end