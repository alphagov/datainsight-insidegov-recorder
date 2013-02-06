require "json"

require "bundler/setup"
Bundler.require(:default, :recorder)
require "datainsight_recorder/recorder"

require_relative "model/policy_entries"
require_relative "model/format_visits"
require_relative "model/content_engagement_visits"
require_relative "model/weekly_reach"

class Recorder
  include DataInsight::Recorder::AMQP

  def queue_name
    "datainsight_insidegov_recorder"
  end

  def routing_keys
    [
      "google_analytics.insidegov.entry_and_success.weekly",
      "google_analytics.insidegov.policy_entries.weekly",
      "google_analytics.insidegov.content_engagement.weekly",
      "google_analytics.inside_gov.visitors.weekly",
      "inside_gov.policies"
    ]
  end

  def update_message(message)
    routing_key = message[:envelope][:_routing_key]
    case routing_key
      when "google_analytics.insidegov.entry_and_success.weekly"
        FormatVisits.update_from_message(message)
      when "google_analytics.insidegov.policy_entries.weekly"
        PolicyEntries.update_from_message(message)
      when "google_analytics.insidegov.content_engagement.weekly"
        ContentEngagementVisits.update_from_message(message)
      when "google_analytics.inside_gov.visitors.weekly"
        WeeklyReach.update_from_message(message)
      when "inside_gov.policies"
        Policy.update_from_message(message)
      else
        raise "Unsupported routing key: #{routing_key}"
    end
  end
end
