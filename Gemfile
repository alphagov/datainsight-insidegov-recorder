source "https://rubygems.org"
source 'https://BnrJb6FZyzspBboNJzYZ@gem.fury.io/govuk/'

gem "rake"
gem "datainsight_recorder", "0.4.1"
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
  gem "database_cleaner"
end
