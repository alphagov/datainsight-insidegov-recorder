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
      PolicyEntries.destroy
      Policy.destroy
    end

    it "should return the last 6 months of data" do
      weeks = 7
      weeks_back = 30
      start_at = DateUtils.sunday_before(Date.today.to_datetime - (weeks_back * weeks))
      end_at = DateUtils.saturday_before(Date.today.to_datetime)

      create_measurements(start_at, end_at, metric: "visitors", value: 500)
      get "/visitors/weekly"

      one_minute = Rational(1, 24*60)

      last_response.content_type.should start_with("application/json")
      json_response = JSON.parse(last_response.body, symbolize_names: true)
      DateTime.parse(json_response[:updated_at]).should be_within(one_minute).of(DateTime.now)
      json_response[:response_info].should == {status: "ok"}
      json_response[:id].should == "/visitors/weekly"
      json_response[:web_url].should == ""
      json_response[:details][:data].length.should be_within(1).of(26)
      json_response[:details][:source].should == ["Google Analytics"]

      data = json_response[:details][:data]
      # start_at of the first element should be within a week of six months ago
      DateTime.parse(data.first[:start_at]).should be_within(1 * weeks).of(Date.today << 6)
      data.first[:value].should == 500
    end

    it "should report error if no data found" do
      get "/visitors/weekly"

      last_response.should be_server_error
    end
  end

  describe "/entries/weekly/policies" do

    after(:each) do
      Policy.destroy
      PolicyEntries.destroy
      FactoryGirl.reload
    end

    it "should serve up a json response" do
      4.times { |n| FactoryGirl.create :policy_entries, entries: n }

      FactoryGirl.create :policy,
                         slug: "sample-policy",
                         title: "Sample Policy",
                         department: "MOD",
                         collected_at: DateTime.parse("2012-12-20T02:00:00+00:00")

      FactoryGirl.create :policy_entries,
                         entries: 123000,
                         slug: "sample-policy",
                         collected_at: DateTime.parse("2012-12-20T01:00:00+00:00")

      get "/entries/weekly/policies"

      last_response.should be_ok
      last_response.content_type.should start_with("application/json")

      json_response = JSON.parse(last_response.body, symbolize_names: true)
      json_response[:response_info].should == {status: "ok"}
      json_response[:updated_at].should == "2012-12-20T01:00:00+00:00"

      json_response[:details][:data].should be_an_instance_of(Array)
      json_response[:details][:data].should have(5).items
      json_response[:details][:data][0][:entries].should == 123000
      json_response[:details][:data][0][:policy][:web_url].should == "https://www.gov.uk/government/policies/sample-policy"
      #json_response[:details][:data][0][:policy][:title].should == "Sample Policy" <-- this needs to be put back when we get policy details
      json_response[:details][:data][0][:policy][:title].should == "missing"
      #json_response[:details][:data][0][:policy][:department].should == "MOD"
      json_response[:details][:data][0][:policy][:department].should == "missing"
      json_response[:details][:data][0][:policy][:updated_at].should == "missing"
    end

    it "should return a response with five policies" do
      10.times { FactoryGirl.create :policy_entries }

      get "/entries/weekly/policies"

      last_response.should be_ok
      last_response.content_type.should start_with("application/json")

      json_response = JSON.parse(last_response.body, symbolize_names: true)
      result = json_response[:details][:data]
      result.should be_an_instance_of(Array)
      result.should have(5).items
    end

    it "should return the TOP five policies" do
      10.times { |n| FactoryGirl.create :policy_entries, entries: (n+1)*100000 }

      get "/entries/weekly/policies"

      json_response = JSON.parse(last_response.body, symbolize_names: true)
      result = json_response[:details][:data]

      result.should have(5).items
      result.all? { |data| data[:entries] >= 600000 }.should be_true
    end

    it "should error if there are not five policies to return" do
      4.times { FactoryGirl.create :policy_entries }

      get "/entries/weekly/policies"

      last_response.status.should == 503
    end

    it "should deal with the case where there is missing metadata for the top five policies"

  end
end