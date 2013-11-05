require "rspec"
require "bundler/setup"
Bundler.require(:default, :test)

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter "/spec/"
end

ENV["RACK_ENV"] = "test"
require "factory_girl"
require "datainsight_logging"
require "datainsight_recorder/datamapper_config"

require_relative "../lib/model/weekly_reach"
require_relative "../lib/model/format_visits"
require_relative "../lib/model/content_engagement_visits"

require "timecop"

FactoryGirl.find_definitions
Datainsight::Logging.configure(:env => :test)
::Logging.logger.root.level = :warn

DataInsight::Recorder::DataMapperConfig.configure(:test)

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.clean_with(:truncation)
  end
end

def create_measurements(start_at, end_at, params={})
  start_at = start_at.to_datetime
  end_at = end_at.to_datetime
  while start_at < end_at
    each_end_at = start_at + 7
    params[:start_at] = DateUtils.localise(start_at)
    params[:end_at] = DateUtils.localise(each_end_at)
    FactoryGirl.create(:model, params)

    start_at += 7
  end
end
