require_relative "spec_helper"
require_relative "../lib/date_series_presenter"

describe DateSeriesPresenter do
  describe "weekly" do
    before(:each) do
      @presenter = DateSeriesPresenter.weekly("")
    end

    it "should correctly convert start and end dates to date objects" do
      visitors =
        [FactoryGirl.build(:model,
                           start_at: DateTime.parse("2011-03-28T00:00:00"),
                           end_at: DateTime.parse("2011-04-04T00:00:00"))]
      Timecop.travel(DateTime.parse("2011-04-19")) do
        response = @presenter.present(visitors)

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
        list = @presenter.add_missing_datapoints(visitors)
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
        list = @presenter.add_missing_datapoints(visitors)
        list.should have(3).items

        list[0][:start_at].should == Date.parse("2011-03-28")
        list[1][:start_at].should == Date.parse("2011-04-04")
        list[1][:value].should be_nil
        list[2][:start_at].should == Date.parse("2011-04-11")
      end
    end

    it "should raise an error if the time period is out by a day" do
      visitors = [
        FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-03-28T00:00:00"),
                          end_at: DateTime.parse("2011-04-05T00:00:00")
        )
      ]
      Timecop.travel(DateTime.parse("2011-04-24")) do
        lambda { @presenter.add_missing_datapoints(visitors) }.should raise_error
      end
    end

    it "should raise an error if the time period is out by an hour" do
      visitors = [
        FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-03-28T00:00:00"),
                          end_at: DateTime.parse("2011-04-04T01:00:00")
        )
      ]
      Timecop.travel(DateTime.parse("2011-04-24")) do
        lambda { @presenter.add_missing_datapoints(visitors) }.should raise_error
      end
    end

    it "should raise an error if start time is not midnight" do
      visitors = [
        FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-03-28T01:00:00"),
                          end_at: DateTime.parse("2011-04-04T01:00:00")
        )]
      Timecop.travel(DateTime.parse("2011-04-24")) do
        lambda { @presenter.add_missing_datapoints(visitors) }.should raise_error
      end
    end

    describe "last_sunday_of" do
      it "should return the same day if argument is already Sunday" do
        @presenter.last_sunday_of(Date.parse("2012-06-13")) == Date.parse("2012-06-13")
      end

      it "should return the previous Sunday day if argument is Saturday" do
        @presenter.last_sunday_of(Date.parse("2012-06-12")) == Date.parse("2012-06-06")
      end

      it "should return the previous Sunday if argument is Monday" do
        @presenter.last_sunday_of(Date.parse("2012-06-07")) == Date.parse("2012-06-06")
      end
    end
  end

  describe "daily" do
    before(:each) do
      @presenter = DateSeriesPresenter.daily("")
    end

    it "should return a valid range" do
      visitors = [
        FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-03-28T00:00:00"),
                          end_at: DateTime.parse("2011-03-29T00:00:00")),
        FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-03-29T00:00:00"),
                          end_at: DateTime.parse("2011-03-30T00:00:00"))
      ]
      Timecop.travel(DateTime.parse("2011-03-30")) do
        list = @presenter.add_missing_datapoints(visitors)
        list.should have(2).items

        list[0][:start_at].strftime.should == "2011-03-28"
        list[0][:value].should == 500

        list[1][:start_at].strftime.should == "2011-03-29"
        list[1][:value].should == 500
      end
    end

    it "should report missing data" do
      visitors = [
        FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-03-28T00:00:00"),
                          end_at: DateTime.parse("2011-03-29T00:00:00")),
        FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-03-30T00:00:00"),
                          end_at: DateTime.parse("2011-03-31T00:00:00"))
      ]

      Timecop.travel(DateTime.parse("2011-04-01")) do
        list = @presenter.add_missing_datapoints(visitors)
        list.should have(4).items

        # in the middle
        list[1][:start_at].strftime.should == "2011-03-29"
        list[1][:value].should be_nil

        # at the end
        list[3][:start_at].strftime.should == "2011-03-31"
        list[3][:value].should be_nil
      end
    end

    it "should raise an error if the time period is not a day" do
      visitors = [
        FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-03-28T00:00:00"),
                          end_at: DateTime.parse("2011-03-28T01:00:00")
        )
      ]
      Timecop.travel(DateTime.parse("2011-03-30")) do
        lambda { @presenter.add_missing_datapoints(visitors) }.should raise_error
      end
    end

    it "should raise an error if start time is not midnight" do
      visitors = [
        FactoryGirl.build(:model,
                          start_at: DateTime.parse("2011-03-28T01:00:00"),
                          end_at: DateTime.parse("2011-03-29T01:00:00")
        )]
      Timecop.travel(DateTime.parse("2011-03-30")) do
        lambda { @presenter.add_missing_datapoints(visitors) }.should raise_error
      end
    end
  end
end