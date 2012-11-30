require_relative "spec_helper"

describe "The weekly reach model" do
  after(:each) do
    WeeklyReach.destroy
  end

  it "should fail storage if value is negative" do
    lambda { WeeklyReach.create(value: -200) }.should raise_error
  end

  it "should report missing data" do
    visitors =
      [FactoryGirl.create(:model,
                          start_at: DateTime.parse("2011-03-28T00:00:00"),
                          end_at: DateTime.parse("2011-04-03T00:00:00")),
       FactoryGirl.create(:model,
                          start_at: DateTime.parse("2011-04-11T00:00:00"),
                          end_at: DateTime.parse("2011-04-17T00:00:00"))]

    Timecop.travel(DateTime.parse("2011-04-19")) do
      list = WeeklyReach.add_missing_datapoints(visitors)
      list.should have(3).items

      list[1][:value].should be_nil
    end
  end

  it "should produce the correct range when on a Sunday" do
    visitors =
      [FactoryGirl.create(:model,
                          start_at: DateTime.parse("2011-03-28T00:00:00"),
                          end_at: DateTime.parse("2011-04-03T00:00:00")),
       FactoryGirl.create(:model,
                          start_at: DateTime.parse("2011-04-11T00:00:00"),
                          end_at: DateTime.parse("2011-04-17T00:00:00"))]

    Timecop.travel(DateTime.parse("2011-04-24")) do
      list = WeeklyReach.add_missing_datapoints(visitors)
      list.should have(3).items

      list[1][:value].should be_nil
    end
  end

  describe "last_sunday_of" do
    it "should return the same day if argument is already Sunday" do
      WeeklyReach.last_sunday_of(Date.parse("2012-06-13")) == Date.parse("2012-06-13")
    end

    it "should return the previous Sunday day if argument is Saturday" do
      WeeklyReach.last_sunday_of(Date.parse("2012-06-12")) == Date.parse("2012-06-06")
    end

    it "should return the previous Sunday if argument is Monday" do
      WeeklyReach.last_sunday_of(Date.parse("2012-06-07")) == Date.parse("2012-06-06")
    end
  end
end
