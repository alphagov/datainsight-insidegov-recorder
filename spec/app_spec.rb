require "rack/test"
require "sinatra/base"
require "json"
require_relative "../lib/app"
require_relative "../lib/model/weekly_reach"

describe "The api layer" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  after(:each) do
    WeeklyReach.destroy
  end

  it "should expose weekly visitors end point" do
    get "/visitors/weekly"
    last_response.should be_ok
  end

  it "should serve up a json response" do
    WeeklyReach.create(
      start_at: DateTime.new(1),
      end_at: DateTime.new(2),
      source: "wibble",
      collected_at: DateTime.new(3),
      value: 9000
    )

    get "/visitors/weekly"
    json_response = JSON.parse(last_response.body, symbolize_names: true)
    json_response[:details][:data].should have(1).item
    json_response[:details][:data].should == [{
                                                start_at: DateTime.new(1).to_s,
                                                end_at: DateTime.new(2).to_s,
                                                value: 9000,
                                              }]
    json_response[:details][:source].should == ["wibble"]
    json_response[:updated_at].should == DateTime.new(3).to_s
    json_response[:response_info].should == {status: "ok"}
    json_response[:id].should == "/visitors/weekly"
    json_response[:web_url].should == ""
  end
end