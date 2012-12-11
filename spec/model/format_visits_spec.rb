require_relative "../spec_helper"
require_relative "../../lib/model/format_visits"
require_relative "../../lib/model/invalid_message_error"

def message(data = {})
  default_message = {
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

  default_message[:payload][:value].merge! data
  
  return default_message
end

describe FormatVisits do
  before(:each) do
    FormatVisits.destroy
  end

  describe "last_week_visits" do
    it "should return visits for the last available week" do
      FactoryGirl.create(:format_visits, format: "f1", start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))
      FactoryGirl.create(:format_visits, format: "f2", start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))

      older_item = FactoryGirl.create(:format_visits, format: "f3", start_at: DateTime.new(2012, 6, 24), end_at: DateTime.new(2012, 7, 1))

      format_visits = FormatVisits.last_week_visits

      format_visits.should have(2).items
      format_visits.should_not include(older_item)
    end
  end

  describe "update_from_message" do
    before(:each) do
      @message = message
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

    it "should update existing data with the same format and period " do
      FormatVisits.update_from_message message(entries: 4000, successes: 2600)
      FormatVisits.update_from_message message(entries: 5000, successes: 3500)

      format_visits = FormatVisits.all

      format_visits.should have(1).object

      format_visits.first.entries.should == 5000
      format_visits.first.successes.should == 3500
    end

    it "should not update existing data if the format is different " do
      FormatVisits.update_from_message message(format: "policy", entries: 4000, successes: 2600)
      FormatVisits.update_from_message message(format: "news", entries: 3000, successes: 2250)

      format_visits = FormatVisits.all

      format_visits.should have(2).object
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
end
