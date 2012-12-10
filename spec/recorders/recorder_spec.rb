require_relative "../spec_helper"
require_relative "../../lib/recorders/recorder"
require "datainsight_recorder/test_helpers"

describe Recorder do
  it "should listen to the correct topic" do
    should_listen_to_topics(
      "google_analytics.insidegov.policy_entries.weekly",
      "google_analytics.inside_gov.visitors.weekly"
    )

    Recorder.new.run
  end

  it "should be able to process messages for registered routing keys" do
    WeeklyReach.should_receive(:update_from_message)
    PolicyEntries.should_receive(:update_from_message)

    recorder = Recorder.new
    recorder.routing_keys.each do |key|
      expect {
        recorder.update_message(envelope: {_routing_key: key})
      }.to_not raise_error
    end
  end
end
