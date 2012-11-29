require "rspec"
require "bundler/setup"
Bundler.require

ENV["RACK_ENV"] = "test"
require "factory_girl"
require_relative "../lib/datamapper_config"
require_relative "../lib/model/weekly_reach"

require "timecop"

FactoryGirl.find_definitions
Datainsight::Logging.configure(:env => :test)
DataMapperConfig.configure(:test)