require_relative "../spec_helper"
require_relative "../../lib/recorder"
require "datainsight_recorder/test_helpers"

describe Recorder do
  before(:each) do
    @recorder = Recorder.new

    @message = {
      :envelope => {},
      :payload => {}
    }
  end


  it "should listen to the correct topic" do
    should_listen_to_topics(
      "google_analytics.insidegov.policy_entries.weekly",
      "google_analytics.insidegov.content_engagement.weekly",
      "google_analytics.inside_gov.visitors.weekly",
      "google_analytics.insidegov.entry_and_success.weekly",
      "inside_gov.policies",
      "inside_gov.artefacts"
    )

    @recorder.run
  end

  it "should be able to process messages for registered routing keys" do
    WeeklyReach.should_receive(:update_from_message)
    PolicyEntries.should_receive(:update_from_message)
    ContentEngagementVisits.should_receive(:update_from_message)
    FormatVisits.should_receive(:update_from_message)
    Policy.should_receive(:update_from_message)
    Artefact.should_receive(:update_from_message)

    @recorder.routing_keys.each do |key|
      expect {
        @recorder.update_message(@message.merge(envelope: {_routing_key: key}))
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

  it "should send content engagement messages to the ContentEngagementVisits model" do
    ContentEngagementVisits.should_receive(:update_from_message)
    @recorder.update_message(envelope: {_routing_key: "google_analytics.insidegov.content_engagement.weekly"})
  end

  it "should send policy messages to the Policy model" do
    Policy.should_receive(:update_from_message)
    @recorder.update_message(envelope: {_routing_key: "inside_gov.policies"})
  end

  it "should send artefact messages to the Artefact model" do
    Artefact.should_receive(:update_from_message)
    @recorder.update_message(@message.merge(envelope: {_routing_key: "inside_gov.artefacts"}))
  end

  it "should send policy artefacts to the Policy model" do
    Artefact.should_receive(:update_from_message)
    Policy.should_receive(:update_from_message)

    @recorder.update_message(
      envelope: {_routing_key: "inside_gov.artefacts"},
      payload: {type: "policy"}
    )
  end
end
