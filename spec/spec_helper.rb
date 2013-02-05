require "rspec"
require "bundler/setup"
Bundler.require(:default, :test)

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter "/spec/"
end

ENV["RACK_ENV"] = "test"
require "factory_girl"
require_relative "../lib/datamapper_config"
require_relative "../lib/model/weekly_reach"
require_relative "../lib/model/format_visits"
require_relative "../lib/model/content_engagement_visits"

require "timecop"

FactoryGirl.find_definitions
Datainsight::Logging.configure(:env => :test)
DataMapperConfig.configure(:test)

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.clean_with(:truncation)
  end
end


def create_measurements(start_at, end_at, params={})
  while start_at < end_at
    each_end_at = start_at + 7
    params[:start_at] = start_at
    params[:end_at] = each_end_at
    FactoryGirl.create(:model, params)

    start_at += 7
  end
end
