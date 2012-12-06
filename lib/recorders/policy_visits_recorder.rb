require "json"

require "bundler/setup"
Bundler.require(:default, :recorder)
require "datainsight_recorder/recorder"

require_relative "../model/policy_visits"

class PolicyVisitsRecorder
  include DataInsight::Recorder::AMQP

  def routing_keys
    ["google_analytics.insidegov.policy_visits.weekly"]
  end

  def update_message(message)
    PolicyVisits.update_from_message(message)
  end
end
