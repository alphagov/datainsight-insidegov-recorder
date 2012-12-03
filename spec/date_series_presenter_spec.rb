require_relative "spec_helper"
require_relative "../lib/date_series_presenter"

describe DateSeriesPresenter do
  it "should correctly convert end_at to a date" do
    visitors =
      [FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-03-28T00:00:00"),
                          end_at: DateTime.parse("2011-04-04T00:00:00"))]
    Timecop.travel(DateTime.parse("2011-04-19")) do
      response = DateSeriesPresenter.new("").present(visitors)

      response.is_error?.should be_false
      response.raw[:details][:data][0][:start_at].should == Date.parse("2011-03-28")
      response.raw[:details][:data][0][:end_at].should == Date.parse("2011-04-03")
    end
  end

  it "should report missing data" do
    visitors =
      [FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-03-28T00:00:00"),
                          end_at: DateTime.parse("2011-04-04T00:00:00")),
       FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-04-11T00:00:00"),
                          end_at: DateTime.parse("2011-04-18T00:00:00"))]

    Timecop.travel(DateTime.parse("2011-04-19")) do
      list = DateSeriesPresenter.new("").add_missing_datapoints(visitors)
      list.should have(3).items

      list[1][:start_at].should == Date.parse("2011-04-04")
      list[1][:value].should be_nil
    end
  end

  it "should produce the correct range when on a Sunday" do
    visitors =
      [FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-03-28T00:00:00"),
                          end_at: DateTime.parse("2011-04-04T00:00:00")),
       FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-04-11T00:00:00"),
                          end_at: DateTime.parse("2011-04-18T00:00:00"))]

    Timecop.travel(DateTime.parse("2011-04-24")) do
      list = DateSeriesPresenter.new("").add_missing_datapoints(visitors)
      list.should have(3).items

      list[0][:start_at].should == Date.parse("2011-03-28")
      list[1][:start_at].should == Date.parse("2011-04-04")
      list[1][:value].should be_nil
      list[2][:start_at].should == Date.parse("2011-04-11")
    end
  end

  describe "last_sunday_of" do
    it "should return the same day if argument is already Sunday" do
      DateSeriesPresenter.new("").last_sunday_of(Date.parse("2012-06-13")) == Date.parse("2012-06-13")
    end

    it "should return the previous Sunday day if argument is Saturday" do
      DateSeriesPresenter.new("").last_sunday_of(Date.parse("2012-06-12")) == Date.parse("2012-06-06")
    end

    it "should return the previous Sunday if argument is Monday" do
      DateSeriesPresenter.new("").last_sunday_of(Date.parse("2012-06-07")) == Date.parse("2012-06-06")
    end
  end
end