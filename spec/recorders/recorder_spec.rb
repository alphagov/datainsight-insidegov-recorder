require_relative "../spec_helper"
require_relative "../../lib/recorder"
require "datainsight_recorder/test_helpers"

describe Recorder do
  before(:each) do
    @recorder = Recorder.new
  end
  it "should listen to the correct topic" do
    should_listen_to_topics(
      "google_analytics.insidegov.policy_entries.weekly",
      "google_analytics.inside_gov.visitors.weekly",
      "google_analytics.insidegov.entry_and_success.weekly",
      "inside_gov.policies"
    )

    @recorder.run
  end

  it "should be able to process messages for registered routing keys" do
    WeeklyReach.should_receive(:update_from_message)
    PolicyEntries.should_receive(:update_from_message)
    FormatVisits.should_receive(:update_from_message)
    Policy.should_receive(:update_from_message)

    @recorder.routing_keys.each do |key|
      expect {
        @recorder.update_message(envelope: {_routing_key: key})
      }.to_not raise_error
    end
  end

  it "should send weekly reach messages to the WeeklyReach model" do
    WeeklyReach.should_receive(:update_from_message)
    @recorder.update_message(envelope: {_routing_key: "google_analytics.inside_gov.visitors.weekly"})
  end

  it "should send entry and success messages to the FormatVisits model" do
    FormatVisits.should_receive(:update_from_message)
    @recorder.update_message(envelope: {_routing_key: "google_analytics.insidegov.entry_and_success.weekly"})
  end

  it "should send policy entry messages to the PolicyEntries model" do
    PolicyEntries.should_receive(:update_from_message)
    @recorder.update_message(envelope: {_routing_key: "google_analytics.insidegov.policy_entries.weekly"})
  end

  it "should send policy messages to the Policy model" do
    Policy.should_receive(:update_from_message)
    @recorder.update_message(envelope: {_routing_key: "inside_gov.policies"})
  end
end
