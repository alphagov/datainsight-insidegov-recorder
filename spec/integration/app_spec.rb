require_relative "spec_helper"
require "json"

describe "The api layer" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe "/visitors/weekly" do
    before(:each) do
    end

    after(:each) do
      WeeklyReach.destroy
      PolicyVisits.destroy
      Policy.destroy
    end

    def last_sunday_of(date_time)
      date_time - (date_time.wday == 0 ? 7 : date_time.wday)
    end

    def last_saturday_of(date_time)
      date_time - (date_time.wday + 1)
    end

    it "should serve up a json response" do
      weeks = 7
      start_at ||= last_sunday_of(DateTime.now - (24 * weeks))
      end_at ||= last_saturday_of(DateTime.now)
      end_date_of_a_first_week = DateTime.now - (23 * weeks)

      create_measurements(start_at, end_at, metric: "visitors", value: 500)
      get "/visitors/weekly"

      one_minute = Rational(1, 24*60)

      last_response.content_type.should start_with("application/json")
      json_response = JSON.parse(last_response.body, symbolize_names: true)
      DateTime.parse(json_response[:updated_at]).should be_within(one_minute).of(DateTime.now)
      json_response[:response_info].should == {status: "ok"}
      json_response[:id].should == "/visitors/weekly"
      json_response[:web_url].should == ""
      json_response[:details][:data].should have(25).items
      json_response[:details][:source].should == ["Google Analytics"]

      data = json_response[:details][:data]
      data.first[:end_at].should == last_saturday_of(end_date_of_a_first_week).to_date.strftime
      data.first[:value].should == 500
    end

    it "should report error if no data found" do
      get "/visitors/weekly"

      last_response.should be_server_error
    end
  end

  describe "/visits/weekly/policies" do
    it "should serve up a json response" do
      FactoryGirl.create :policy, slug: "/government/policy/sample-policy", title: "Sample Policy", department: "MOD", updated_at: DateTime.parse("2012-11-19T16:00:07+00:00")
      FactoryGirl.create :policy_visits, visits: 123000, slug: "/government/policy/sample-policy"

      get "/visits/weekly/policies"

      last_response.should be_ok
      last_response.content_type.should start_with("application/json")

      json_response = JSON.parse(last_response.body, symbolize_names: true)
      json_response[:response_info].should == {status: "ok"}
      json_response[:details][:data].should be_an_instance_of(Array)
      json_response[:details][:data].should have(1).items
      json_response[:details][:data][0][:visits].should == 123000
      json_response[:details][:data][0][:policy][:web_url].should == "https://www.gov.uk/government/policy/sample-policy"
      json_response[:details][:data][0][:policy][:title].should == "Sample Policy"
      json_response[:details][:data][0][:policy][:department].should == "MOD"
      json_response[:details][:data][0][:policy][:updated_at].should == "2012-11-19T16:00:07+00:00"
    end
  end
end