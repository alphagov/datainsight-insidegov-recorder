require_relative "spec_helper"
require_relative "../lib/recorder"
require_relative "../lib/model/weekly_reach"
require "datainsight_recorder/test_helpers"

describe "Recorder" do

  it "should listen to the correct topic" do
    should_listen_to_topics(
      "google_analytics.inside_gov.visitors.weekly"
    )

    Recorder.new.run
  end

  it "should send message to correct model" do
    recorder = Recorder.new
    queue = mock()
    recorder.stub(:queue).and_return(queue)

    amqp_message = {
      delivery_details: {
        routing_key: "foo"
      },
      payload: '{"envelope":{}}'
    }

    parsed_message = {
      envelope: {
        _routing_key: "foo"
      }
    }

    queue.should_receive(:subscribe).and_yield(amqp_message)

    WeeklyReach.should_receive(:update_from_message).with(parsed_message)

    recorder.run
  end
end
