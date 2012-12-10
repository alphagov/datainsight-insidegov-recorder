require_relative "../spec_helper"
require_relative "../../lib/model/format_visits"
require_relative "../../lib/model/invalid_message_error"

describe FormatVisits do
  before(:each) do
    FormatVisits.destroy

    @message = {
      envelope: {
        collected_at: "2011-04-05T12:15:35",
        collector: "Google Analytics",
        _routing_key: "google_analytics.insidegov.entry_and_success.weekly"
      },
      payload: {
        start_at: "2011-03-28T00:00:00",
        end_at: "2011-04-04T00:00:00",
        value: {
            site: "insidegov",
            format: "policy",
            entries: 4567,
            successes: 2345
        }
      }
    }
  end

  it "should store weekly entries and successes when processing drive message" do
    FormatVisits.update_from_message(@message)

    format_visits = FormatVisits.all

    format_visits.should_not be_empty
    format_visits.first.collected_at.should == DateTime.new(2011, 4, 5, 12, 15, 35)
    format_visits.first.source.should == "Google Analytics"
    format_visits.first.start_at.should == Date.new(2011, 3, 28)
    format_visits.first.end_at.should == Date.new(2011, 4, 4)
    format_visits.first.format.should == "policy"
    format_visits.first.entries.should == 4567
    format_visits.first.successes.should == 2345
  end

  it "should update existing measurements" do
    a_message = @message
    another_message_for_the_same_period = @message.tap { |m|
      m[:payload][:value][:entries] = 5000
      m[:payload][:value][:successes] = 3500
    }

    FormatVisits.update_from_message a_message

    FormatVisits.update_from_message another_message_for_the_same_period

    format_visits = FormatVisits.all

    format_visits.should have(1).object

    format_visits.first.entries.should == 5000
    format_visits.first.successes.should == 3500
  end

  describe "validation" do
    it "should fail if message is empty" do
      lambda { FormatVisits.update_from_message({}) }.should raise_error InvalidMessageError
    end

    it "should fail if collected_at property is not present" do
      @message[:envelope].delete :collected_at
      lambda { FormatVisits.update_from_message(@message) }.should raise_error InvalidMessageError
    end

    it "should fail if collected_at property is not a valid date" do
      @message[:envelope][:collected_at] = "not a date"
      lambda { FormatVisits.update_from_message(@message) }.should raise_error InvalidMessageError
    end

    it "should fail if collector property is not present" do
      @message[:envelope].delete :collector
      lambda { FormatVisits.update_from_message(@message) }.should raise_error InvalidMessageError
    end

    it "should fail if start_at property is not present" do
      @message[:payload].delete :start_at
      lambda { FormatVisits.update_from_message(@message) }.should raise_error InvalidMessageError
    end

    it "should fail if end_at property is not present" do
      @message[:payload].delete :end_at
      lambda { FormatVisits.update_from_message(@message) }.should raise_error InvalidMessageError
    end

    it "should fail if format property is not present" do
      @message[:payload][:value].delete :format
      lambda { FormatVisits.update_from_message(@message) }.should raise_error InvalidMessageError
    end

    it "should fail if entries property is not present" do
      @message[:payload][:value].delete :entries
      lambda { FormatVisits.update_from_message(@message) }.should raise_error InvalidMessageError
    end

    it "should fail if successes property is not present" do
      @message[:payload][:value].delete :successes
      lambda { FormatVisits.update_from_message(@message) }.should raise_error InvalidMessageError
    end

    it "should fail if successes property is not an integer" do
      @message[:payload][:value][:successes] = "a"
      lambda { FormatVisits.update_from_message(@message) }.should raise_error InvalidMessageError
    end
  end
end
