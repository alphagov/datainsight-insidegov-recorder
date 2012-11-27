require "rspec"
require "datamapper_config"
require_relative "../lib/model/weekly_reach"

ENV['RACK_ENV'] = 'test'

DataMapperConfig.configure(:test)

describe "The weekly reach model" do

  after(:each) do
    WeeklyReach.destroy
  end

  it "should fail storage if value is negative" do
    lambda { WeeklyReach.create(value: -200) }.should raise_error
  end

  it "should be able to retrieve values by start_at and end_at" do
    WeeklyReach.create(value: 100,
                       start_at: DateTime.new(1),
                       end_at: DateTime.new(2),
                       collected_at: DateTime.now,
                       source: "Pawel")

    WeeklyReach.create(value: 100,
                       start_at: DateTime.new(3),
                       end_at: DateTime.new(4),
                       collected_at: DateTime.now,
                       source: "Data is better in Krakow")

    WeeklyReach.retrieve(DateTime.new(1), DateTime.new(2)).first.source.should == "Pawel"
  end
end