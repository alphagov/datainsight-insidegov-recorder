require_relative "../spec_helper"
require_relative "../../lib/recorder"
require_relative "../../lib/model/weekly_reach"

describe "WeeklyVisitorsRecorder" do
  before(:each) do
    @message = {
        :envelope => {
            :collected_at => DateTime.now.strftime,
            :collector    => "Google Analytics",
            :_routing_key => "google_analytics.inside_gov.visitors.weekly"
        },
        :payload => {
            :start_at => "2011-03-28T00:00:00",
            :end_at => "2011-04-04T00:00:00",
            :value => {
              :visitors => 700,
              :site => "insidegov"
            }
        }
    }
    @recorder = Recorder.new
  end

  after :each do
    WeeklyReach.destroy
  end

  it "should store weekly visitors when processing drive message" do
    @recorder.process_message(@message)

    WeeklyReach.all.should_not be_empty
    item = WeeklyReach.first
    item.metric.should == "visitors"
    item.value.should == 700
    item.start_at.should == Date.new(2011, 3, 28)
    item.end_at.should == Date.new(2011, 4, 3)
  end

  it "should delete the record when processing a nil drive message" do
    FactoryGirl.create(:model,
        metric: "visitors",
        start_at: DateTime.parse("2011-03-28T00:00:00"),
        end_at: DateTime.parse("2011-04-03T00:00:00"),
        value: 700
    )
    @message[:payload][:value][:visitors] = nil
    @recorder.process_message(@message)

    WeeklyReach.all.should be_empty
  end

  it "should store weekly data when processing analytics message" do
    @message[:payload][:value][:site] = "govuk"
    @recorder.process_message(@message)

    WeeklyReach.all.should_not be_empty
    item = WeeklyReach.first
    item.metric.should == "visitors"
    item.value.should == 700
    item.start_at.should == Date.new(2011, 3, 28)
    item.end_at.should == Date.new(2011, 4, 3)
  end

  it "should correctly handle end date over month boundaries" do
    @message[:payload][:start_at] = "2011-08-25T00:00:00"
    @message[:payload][:end_at] = "2011-09-01T00:00:00"
    @recorder.process_message(@message)
    item = WeeklyReach.first
    item.end_at.should == Date.new(2011, 8, 31)
  end

  it "should store visitors metric" do
    @message[:envelope][:_routing_key] = "google_analytics.visitors.weekly"
    @message[:payload][:value][:visitors] = @message[:payload][:value].delete(:visitors)
    @recorder.process_message(@message)
    item = WeeklyReach.first
    item.metric.should == "visitors"
  end

  it "should raise an error with invalid week on insert" do
    @message[:payload][:start_at] = "2011-03-29T00:00:00" #to short week
    lambda do
      @recorder.process_message(@message)
    end.should raise_error
  end

  it "should update existing measurements" do
    @recorder.process_message(@message)
    @message[:payload][:value][:visitors] = 900
    @recorder.process_message(@message)
    WeeklyReach.all.length.should == 1
    WeeklyReach.first.value.should == 900
  end

  describe "validation" do
    it "should fail if value is not present" do
      @message[:payload].delete(:value)

      lambda do
        @recorder.process_message(@message)
      end.should raise_error
    end

    it "should fail if value is not nil and cannot be parsed as a integer" do
      @message[:payload][:value] = "invalid"

      lambda do
        @recorder.process_message(@message)
      end.should raise_error
    end

    it "should allow nil as a value" do
      @message[:payload][:value][:visitors] = nil

      lambda do
        @recorder.process_message(@message)
      end.should_not raise_error
    end

  end
end
