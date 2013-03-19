require_relative "time_period_presenter"

class PolicyPresenter
  def present(policies)
    TimePeriodPresenter.new.present(policies) do |policy_entry|
      {
        entries: policy_entry.entries,
        policy: {
          title: policy_entry.policy.title,
          web_url: "https://www.gov.uk/government/policies/#{policy_entry.slug}",
          updated_at: policy_entry.policy.artefact_updated_at.strftime(TimePeriodPresenter::TIMESTAMP_FORMAT),
          organisations: JSON.parse(policy_entry.policy.organisations)
        }
      }
    end
  end
end