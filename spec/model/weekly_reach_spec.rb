require_relative "../spec_helper"
require_relative "../../lib/date_utils"

describe "The weekly reach model" do
  it "should fail storage if value is negative" do
    lambda { WeeklyReach.create(value: -200) }.should raise_error
  end

  describe "update_from_message" do

    before(:each) do
      @message = {
        :envelope => {
          :collected_at => DateTime.now.strftime,
          :collector    => "Google Analytics",
          :_routing_key => "google_analytics.inside_gov.visitors.weekly"
        },
        :payload => {
          :start_at => "2011-03-28T00:00:00+01:00",
          :end_at => "2011-04-04T00:00:00+01:00",
          :value => {
            :visitors => 700,
            :site => "insidegov"
          }
        }
      }
    end

    it "should store weekly visitors when processing drive message" do
      WeeklyReach.update_from_message(@message)

      WeeklyReach.all.should_not be_empty
      item = WeeklyReach.first
      item.metric.should == "visitors"
      item.value.should == 700
      item.start_at.should == DateTime.parse("2011-03-28T00:00:00+01:00")
      item.end_at.should == DateTime.parse("2011-04-04T00:00:00+01:00")
    end

    it "should store weekly data when processing analytics message" do
      @message[:payload][:value][:site] = "govuk"
      WeeklyReach.update_from_message(@message)

      WeeklyReach.all.should_not be_empty
      item = WeeklyReach.first
      item.metric.should == "visitors"
      item.value.should == 700
      item.start_at.should == DateTime.parse("2011-03-28T00:00:00+01:00")
      item.end_at.should == DateTime.parse("2011-04-04T00:00:00+01:00")
    end

    it "should store visitors metric" do
      @message[:envelope][:_routing_key] = "google_analytics.visitors.weekly"
      @message[:payload][:value][:visitors] = @message[:payload][:value].delete(:visitors)
      WeeklyReach.update_from_message(@message)
      item = WeeklyReach.first
      item.metric.should == "visitors"
    end

    it "should raise an error with invalid week on insert" do
      @message[:payload][:start_at] = "2011-03-29T00:00:00" #to short week
      lambda do
        WeeklyReach.update_from_message(@message)
      end.should raise_error
    end

    it "should update existing measurements" do
      WeeklyReach.update_from_message(@message)
      @message[:payload][:value][:visitors] = 900
      WeeklyReach.update_from_message(@message)
      WeeklyReach.all.length.should == 1
      WeeklyReach.first.value.should == 900
    end

    describe "validation" do
      it "should fail if value is not present" do
        @message[:payload].delete(:value)

        lambda do
          WeeklyReach.update_from_message(@message)
        end.should raise_error
      end

      it "should fail if value is not nil and cannot be parsed as a integer" do
        @message[:payload][:value] = "invalid"

        lambda do
          WeeklyReach.update_from_message(@message)
        end.should raise_error
      end

      it "should allow nil as a value" do
        @message[:payload][:value][:visitors] = nil

        lambda do
          WeeklyReach.update_from_message(@message)
        end.should_not raise_error
      end

    end

  end

  describe "last_twelve_weeks" do
    it "should return the last twelve weeks of data" do
      start_at = DateUtils.sunday_before(Date.parse("2012-12-01")) << 8
      end_at = DateUtils.saturday_before(Date.parse("2012-12-01").to_datetime)
      create_measurements(start_at, end_at, metric: "visitors", value: 500)

      Timecop.travel(DateTime.parse("2012-12-04")) do
        data = WeeklyReach.last_twelve_weeks

        data.first[:start_at].should == DateUtils.localise(DateTime.parse("2012-09-09"))
        data.last[:start_at].should == DateUtils.localise(DateTime.parse("2012-11-18"))
      end
    end
  end

  describe "last_six_months" do
    it "should return the last six months of data" do
      start_at = DateUtils.sunday_before(Date.parse("2012-12-01")) << 8
      end_at = DateUtils.saturday_before(Date.parse("2012-12-01").to_datetime)
      create_measurements(start_at, end_at, metric: "visitors", value: 500)

      Timecop.travel(DateTime.parse("2012-12-04")) do
        data = WeeklyReach.last_six_months

        data.first[:start_at].should == DateUtils.localise(DateTime.parse("2012-06-03"))
        data.last[:start_at].should == DateUtils.localise(DateTime.parse("2012-11-18"))
      end
    end
  end
end
