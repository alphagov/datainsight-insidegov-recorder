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

    it "should return the last 12 weeks of data" do
      Timecop.travel(DateTime.parse("2012-12-13")) do
        weeks = 7
        weeks_back = 30
        start_at = DateUtils.sunday_before(Date.today.to_datetime - (weeks_back * weeks))
        end_at = DateUtils.saturday_before(Date.today.to_datetime)
        data_collection_date = DateTime.now

        create_measurements(start_at, end_at, metric: "visitors", value: 500, collected_at: data_collection_date)
        get "/visitors/weekly"

        one_minute = Rational(1, 24*60)

        last_response.content_type.should start_with("application/json")
        json_response = JSON.parse(last_response.body, symbolize_names: true)
        json_response[:updated_at].should == data_collection_date.strftime
        json_response[:response_info].should == {status: "ok"}
        json_response[:id].should == "/visitors/weekly"
        json_response[:web_url].should == ""
        json_response[:details][:data].length.should == 12
        json_response[:details][:source].should == ["Google Analytics"]

        data = json_response[:details][:data]
        data.first[:start_at].should == "2012-09-16" # sunday 12 weeks before today
        data.first[:value].should == 500
      end
    end

    it "should report error if no data found" do
      get "/visitors/weekly"

      last_response.should be_server_error
    end
  end

  describe "/entries/weekly/policies" do

    it "should serve up a json response" do
      9.times { |n| FactoryGirl.create :policy_entries, entries: n }

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
      json_response[:details][:data].should have(10).items
      json_response[:details][:data][0][:entries].should == 123000
      json_response[:details][:data][0][:policy][:web_url].should == "https://www.gov.uk/government/policies/sample-policy"
      #json_response[:details][:data][0][:policy][:title].should == "Sample Policy" <-- this needs to be put back when we get policy details
      json_response[:details][:data][0][:policy][:title].should == "missing"
      #json_response[:details][:data][0][:policy][:department].should == "MOD"
      json_response[:details][:data][0][:policy][:department].should == "missing"
      json_response[:details][:data][0][:policy][:updated_at].should == "missing"
    end

    it "should return a response with ten policies" do
      10.times { FactoryGirl.create :policy_entries }

      get "/entries/weekly/policies"

      last_response.should be_ok
      last_response.content_type.should start_with("application/json")

      json_response = JSON.parse(last_response.body, symbolize_names: true)
      result = json_response[:details][:data]
      result.should be_an_instance_of(Array)
      result.should have(10).items
    end

    it "should return the TOP ten policies" do
      15.times { |n| FactoryGirl.create :policy_entries, entries: (n+1)*100000 }

      get "/entries/weekly/policies"

      json_response = JSON.parse(last_response.body, symbolize_names: true)
      result = json_response[:details][:data]

      result.should have(10).items
      result.all? { |data| data[:entries] >= 600000 }.should be_true
    end

    it "should error if there are not ten policies to return" do
      4.times { FactoryGirl.create :policy_entries }

      get "/entries/weekly/policies"

      last_response.status.should == 503
    end

    it "should deal with the case where there is missing metadata for the top ten policies"

  end

  describe "/format-success/weekly" do
    it "should return format success data for the last week in json format" do
      FactoryGirl.create(:format_visits, source: "format-data-source", format: "news", entries: 1000, successes: 500, collected_at: DateTime.new(2012, 10, 3, 12, 0, 0))
      FactoryGirl.create(:format_visits, source: "format-data-source", format: "policy", entries: 2345, successes: 1489, collected_at: DateTime.new(2012, 10, 3, 13, 0, 0))

      get "/format-success/weekly"

      last_response.status.should == 200
      last_response.content_type.should start_with("application/json")

      resource = JSON.parse last_response.body, symbolize_names: true

      resource[:response_info][:status].should == "ok"
      resource[:details][:source].should == ["format-data-source"]
      resource[:updated_at].should == "2012-10-03T13:00:00+00:00"
      resource[:details][:data].should have(2).item
      resource[:details][:data][0][:format].should == "news"
      resource[:details][:data][0][:entries].should == 1000
      resource[:details][:data][0][:percentage_of_success].should == 50.0
      resource[:details][:data][1][:format].should == "policy"
      resource[:details][:data][1][:entries].should == 2345
      resource[:details][:data][1][:percentage_of_success].should be_within(0.0001).of(63.4968)
    end
  end
end