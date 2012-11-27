require "bundler/setup"
Bundler.require(:default, :exposer)
require "model/weekly_reach"

get "/visitors/weekly" do
  WeeklyReach.json_representation
end