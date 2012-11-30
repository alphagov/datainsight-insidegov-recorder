require_relative "spec_helper"
require "json"

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

  def last_sunday_of(date_time)
    date_time - (date_time.wday == 0 ? 7 : date_time.wday)
  end

  def last_saturday_of(date_time)
    date_time - (date_time.wday + 1)
  end

  it "should serve up a json response" do
    start_at ||= last_sunday_of(DateTime.now << 6)
    end_at ||= last_saturday_of(DateTime.now)
    end_date_of_a_first_week = (DateTime.now << 6) + 7

    create_measurements(start_at, end_at, metric: "visitors", value: 500)

    get "/visitors/weekly"

    one_minute = Rational(1, 24*60)

    json_response = JSON.parse(last_response.body, symbolize_names: true)
    DateTime.parse(json_response[:updated_at]).should be_within(one_minute).of(DateTime.now)
    json_response[:response_info].should == {status: "ok"}
    json_response[:id].should == "/visitors/weekly"
    json_response[:web_url].should == ""
    json_response[:details][:data].should have(27).item
    json_response[:details][:source].should == ["Google Analytics"]

    data = json_response[:details][:data]
    data.first[:end_at].should == last_saturday_of(end_date_of_a_first_week).to_date.strftime
    data.first[:value].should == 500
  end
end