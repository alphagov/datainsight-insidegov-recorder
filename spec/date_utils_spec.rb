require_relative "spec_helper"
require_relative "../lib/date_utils"

describe DateUtils do
  describe "last_sunday_for" do
    it "should return the previous Sunday for a Saturday" do
      DateUtils.last_sunday_for(Date.new(2012, 12, 8)).should == Date.new(2012, 12, 2)
    end

    it "should return the previous Sunday for a Monday" do
      DateUtils.last_sunday_for(Date.new(2012, 12, 3)).should == Date.new(2012, 12, 2)
    end
    it "should return the same day for a Sunday" do
      DateUtils.last_sunday_for(Date.new(2012, 12, 2)).should == Date.new(2012, 12, 2)
    end
  end

  describe "sunday_before" do
    it "should return the previous Sunday for a Saturday" do
      DateUtils.sunday_before(Date.new(2012, 12, 8)).should == Date.new(2012, 12, 2)
    end

    it "should return the previous Sunday for a Monday" do
      DateUtils.sunday_before(Date.new(2012, 12, 3)).should == Date.new(2012, 12, 2)
    end

    it "should return the previous Sunday for a Sunday" do
      DateUtils.sunday_before(Date.new(2012, 12, 2)).should == Date.new(2012, 11, 25)
    end
  end

  describe "saturday_before" do
    it "should return the previous Saturday for a Sunday" do
      DateUtils.saturday_before(Date.new(2012, 12, 9)).should == Date.new(2012, 12, 8)
    end

    it "should return the previous Saturday for a Friday" do
      DateUtils.saturday_before(Date.new(2012, 12, 7)).should == Date.new(2012, 12, 1)
    end

    it "should return the same day for a Saturday" do
      DateUtils.saturday_before(Date.new(2012, 12, 8)).should == Date.new(2012, 12, 1)
    end
  end
end