require "json"

require "bundler/setup"
Bundler.require(:default, :recorder)
require "datainsight_recorder/recorder"

require_relative "../model/weekly_reach"

class WeeklyVisitorsRecorder
  include DataInsight::Recorder::AMQP

  def routing_keys
    ["google_analytics.inside_gov.visitors.weekly"]
  end

  def update_message(message)
    WeeklyReach.update_from_message(message)
  end
end
