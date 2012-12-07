require "json"

require "bundler/setup"
Bundler.require(:default, :recorder)
require "datainsight_recorder/recorder"

require_relative "../model/policy_entries"

class PolicyEntriesRecorder
  include DataInsight::Recorder::AMQP

  def routing_keys
    ["google_analytics.insidegov.policy_visits.weekly"]
  end

  def update_message(message)
    PolicyEntries.update_from_message(message)
  end
end
