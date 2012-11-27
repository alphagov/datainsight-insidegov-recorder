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

end