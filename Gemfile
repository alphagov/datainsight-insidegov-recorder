source "https://rubygems.org"
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

gem "rake"
gem "datainsight_recorder", "0.0.4"
gem "airbrake", "3.1.5"

group :exposer do
  gem "sinatra"
  gem "unicorn"
end

group :recorder do
  gem "bunny"
  gem "gli", "1.6.0"
end

group :test do
  gem "rspec"
  gem "simplecov"
  gem "simplecov-rcov"
  gem "rack-test"
  gem "ci_reporter"
  gem "factory_girl"
  gem "timecop"
end
