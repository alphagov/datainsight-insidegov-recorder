require_relative "../spec_helper"
require_relative "../../lib/presenter/date_series_presenter"

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
        list = @presenter.present(visitors)

        list.is_error?.should be_false
        list.raw[:details][:data][0][:start_at].should == Date.parse("2011-03-28")
        list.raw[:details][:data][0][:end_at].should == Date.parse("2011-04-03")
      end
    end

    describe "response object" do
      it "should be possible to limit the results" do
        visitors =
          [FactoryGirl.build(:model,
                             start_at: DateTime.parse("2012-11-11"),
                             end_at: DateTime.parse("2012-11-18")),
           FactoryGirl.build(:model,
                             start_at: DateTime.parse("2012-11-25"),
                             end_at: DateTime.parse("2012-12-02"))]

        Timecop.travel(DateTime.parse("2012-12-04")) do
          list = @presenter.present(visitors)
          list.raw[:details][:data].should have(3).items

          list = list.limit(2)
          list.raw[:details][:data].should have(2).items
        end
      end

    end

    describe "nil values" do
      it "should be inserted for missing data points" do
        visitors =
          [FactoryGirl.build(:model,
                             start_at: DateTime.parse("2012-11-11"),
                             end_at: DateTime.parse("2012-11-18")),
           FactoryGirl.build(:model,
                             start_at: DateTime.parse("2012-11-25"),
                             end_at: DateTime.parse("2012-12-02"))]

        Timecop.travel(DateTime.parse("2012-12-04")) do
          list = @presenter.add_missing_datapoints(visitors)
          list.should have(3).items

          list[1][:start_at].should == Date.parse("2012-11-18")
          list[1][:value].should be_nil
        end
      end

      it "should be inserted for the previous week on Saturdays" do
        visitors =
          [FactoryGirl.build(:model,
                             start_at: DateTime.parse("2012-11-25"),
                             end_at: DateTime.parse("2012-12-02"))
          ]
        Timecop.travel(DateTime.parse("2012-12-15")) do
          list = @presenter.add_missing_datapoints(visitors)
          list.should have(2).items

          list[1][:start_at].should == Date.parse("2012-12-02")
          list[1][:value].should be_nil
        end
      end

      it "should not be inserted for the previous week on Sundays" do
        visitors =
          [FactoryGirl.build(:model,
                             start_at: DateTime.parse("2012-11-25"),
                             end_at: DateTime.parse("2012-12-02"))
          ]
        Timecop.travel(DateTime.parse("2012-12-09T10:30")) do
          list = @presenter.add_missing_datapoints(visitors)
          list.should have(1).items
        end
      end

      it "should be inserted for the previous week on Mondays" do
        visitors =
          [FactoryGirl.build(:model,
                             start_at: DateTime.parse("2012-11-25"),
                             end_at: DateTime.parse("2012-12-02"))
          ]
        Timecop.travel(DateTime.parse("2012-12-10T10:30")) do
          list = @presenter.add_missing_datapoints(visitors)
          list.should have(2).items

          list[1][:start_at].should == Date.parse("2012-12-02")
          list[1][:value].should be_nil
        end
      end
    end

    describe "validation" do
      it "should fail if the time period is out by a day" do
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

      it "should fail if the time period is out by an hour" do
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

      it "should fail if start time is not midnight" do
        visitors = [
          FactoryGirl.build(:model,
                            start_at: DateTime.parse("2011-03-28T01:00:00"),
                            end_at: DateTime.parse("2011-04-04T01:00:00")
          )]
        Timecop.travel(DateTime.parse("2011-04-24")) do
          lambda { @presenter.add_missing_datapoints(visitors) }.should raise_error
        end
      end
    end

    describe "response data" do
      it "should return data for the previous week on Sunday if available" do
        visitors =
          [FactoryGirl.build(:model,
                             start_at: DateTime.parse("2012-11-25"),
                             end_at: DateTime.parse("2012-12-02")),
           FactoryGirl.build(:model,
                             start_at: DateTime.parse("2012-12-02"),
                             end_at: DateTime.parse("2012-12-09"))
          ]
        Timecop.travel(DateTime.parse("2012-12-09T10:30")) do
          list = @presenter.add_missing_datapoints(visitors)
          list.should have(2).items

          list[1][:start_at].should == Date.parse("2012-12-02")
          list[1][:value].should == 500
        end
      end
    end

  end


  describe "daily" do
    before(:each) do
      @presenter = DateSeriesPresenter.daily("")
    end

    describe "nil values" do
      it "should be inserted for missing data points" do
        visitors = [
          FactoryGirl.build(:model,
                            start_at: DateTime.parse("2012-12-01"),
                            end_at: DateTime.parse("2012-12-02")
          ),
          FactoryGirl.build(:model,
                            start_at: DateTime.parse("2012-12-03"),
                            end_at: DateTime.parse("2012-12-04"))
        ]

        Timecop.travel(DateTime.parse("2012-12-04")) do
          list = @presenter.add_missing_datapoints(visitors)
          list.should have(3).items

          list[1][:start_at].should == Date.parse("2012-12-02")
          list[1][:value].should be_nil
        end
      end

      it "should not be inserted for the previous day" do
        visitors = [
          FactoryGirl.build(:model,
                            start_at: DateTime.parse("2012-12-02"),
                            end_at: DateTime.parse("2012-12-03"))
        ]

        Timecop.travel(DateTime.parse("2012-12-04T10:30")) do
          list = @presenter.add_missing_datapoints(visitors)
          list.should have(1).items
        end
      end

      it "should be inserted for the previous day but one" do
        visitors = [
          FactoryGirl.build(:model,
                            start_at: DateTime.parse("2012-12-02"),
                            end_at: DateTime.parse("2012-12-03"))
        ]

        Timecop.travel(DateTime.parse("2012-12-05T10:30")) do
          list = @presenter.add_missing_datapoints(visitors)
          list.should have(2).items
        end
      end
    end

    describe "validation" do
      it "should fail if the time period is longer than a day" do
        visitors = [
          FactoryGirl.build(:model,
                            start_at: DateTime.parse("2012-12-02T00:00:00"),
                            end_at: DateTime.parse("2012-12-03T01:00:00")
          )
        ]
        Timecop.travel(DateTime.parse("2012-12-04")) do
          lambda { @presenter.add_missing_datapoints(visitors) }.should raise_error
        end
      end
      it "should fail if the time period is shorter than a day" do
        visitors = [
          FactoryGirl.build(:model,
                            start_at: DateTime.parse("2012-12-03T00:00:00"),
                            end_at: DateTime.parse("2012-12-03T23:00:00")
          )
        ]
        Timecop.travel(DateTime.parse("2012-12-04")) do
          lambda { @presenter.add_missing_datapoints(visitors) }.should raise_error
        end
      end
      it "should fail if the start time is not midnight" do
        visitors = [
          FactoryGirl.build(:model,
                            start_at: DateTime.parse("2012-12-02T01:00:00"),
                            end_at: DateTime.parse("2012-12-03T01:00:00")
          )]
        Timecop.travel(DateTime.parse("2012-12-04")) do
          lambda { @presenter.add_missing_datapoints(visitors) }.should raise_error
        end
      end
    end

    describe "response data" do
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
    end
  end
end