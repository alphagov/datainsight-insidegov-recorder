require_relative "spec_helper"
require "json"

describe "The api layer" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe "/visitors/weekly" do
    it "should return the last 6 months of data" do
      Timecop.travel(DateTime.parse("2012-12-13")) do
        weeks = 7
        weeks_back = 30
        start_at = DateUtils.sunday_before(Date.today.to_datetime - (weeks_back * weeks))
        end_at = DateUtils.saturday_before(Date.today.to_datetime)
        data_collection_date = DateTime.now

        create_measurements(start_at, end_at, metric: "visitors", value: 500, collected_at: data_collection_date)
        get "/visitors/weekly"

        last_response.content_type.should start_with("application/json")
        json_response = JSON.parse(last_response.body, symbolize_names: true)
        json_response[:updated_at].should == data_collection_date.strftime
        json_response[:response_info].should == {status: "ok"}
        json_response[:id].should == "/visitors/weekly"
        json_response[:web_url].should == ""
        json_response[:details][:data].length.should == 26
        json_response[:details][:source].should == ["Google Analytics"]

        data = json_response[:details][:data]
        data.first[:start_at].should == "2012-06-10" # sunday 6 months before today
        data.first[:value].should == 500
      end
    end

    it "should be possible to limit the results" do
      Timecop.travel(DateTime.parse("2012-12-13")) do
        weeks = 7
        weeks_back = 30
        start_at = DateUtils.sunday_before(Date.today.to_datetime - (weeks_back * weeks))
        end_at = DateUtils.saturday_before(Date.today.to_datetime)
        data_collection_date = DateTime.now

        create_measurements(start_at, end_at, metric: "visitors", value: 500, collected_at: data_collection_date)
        get "/visitors/weekly?limit=12"

        last_response.content_type.should start_with("application/json")
        json_response = JSON.parse(last_response.body, symbolize_names: true)
        json_response[:updated_at].should == data_collection_date.strftime
        json_response[:response_info].should == {status: "ok"}
        json_response[:id].should == "/visitors/weekly"
        json_response[:web_url].should == ""
        json_response[:details][:data].length.should == 12
        json_response[:details][:source].should == ["Google Analytics"]

        data = json_response[:details][:data]
        data.first[:start_at].should == "2012-09-16" # sunday 6 months before today
        data.first[:value].should == 500
      end
    end

    it "should cap requests to 6 months" do
      Timecop.travel(DateTime.parse("2012-12-13")) do
        weeks = 7
        weeks_back = 30
        start_at = DateUtils.sunday_before(Date.today.to_datetime - (weeks_back * weeks))
        end_at = DateUtils.saturday_before(Date.today.to_datetime)
        data_collection_date = DateTime.now

        create_measurements(start_at, end_at, metric: "visitors", value: 500, collected_at: data_collection_date)
        get "/visitors/weekly?limit=30"

        json_response = JSON.parse(last_response.body, symbolize_names: true)
        json_response[:details][:data].length.should == 26

      end
    end

    it "should correctly limit the results when there is missing data" do
      Timecop.travel(DateTime.parse("2012-12-13")) do
        weeks = 7
        weeks_back = 30
        start_at = DateUtils.sunday_before(Date.today.to_datetime - (weeks_back * weeks))
        end_at = DateUtils.saturday_before(Date.today.to_datetime)
        data_collection_date = DateTime.now

        create_measurements(start_at, end_at - 6 * weeks, metric: "visitors", value: 500, collected_at: data_collection_date)
        create_measurements(end_at - 3 * weeks + 1, end_at, metric: "visitors", value: 500, collected_at: data_collection_date)
        get "/visitors/weekly?limit=12"

        last_response.content_type.should start_with("application/json")
        json_response = JSON.parse(last_response.body, symbolize_names: true)
        json_response[:updated_at].should == data_collection_date.strftime
        json_response[:response_info].should == {status: "ok"}
        json_response[:id].should == "/visitors/weekly"
        json_response[:web_url].should == ""
        json_response[:details][:data].length.should == 12
        json_response[:details][:source].should == ["Google Analytics"]

        data = json_response[:details][:data]
        data.first[:start_at].should == "2012-09-16" # sunday 6 months before today
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
                         organisations: '[{"abbreviation":"MOD","name":"Ministry of defence"}]',
                         policy_updated_at: DateTime.parse("2012-12-19T02:00:00+00:00"),
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

      details = json_response[:details]
      details[:start_at].should == "2012-08-06T00:00:00+00:00"
      details[:end_at].should == "2012-08-13T00:00:00+00:00"

      data = details[:data]
      data.should be_an_instance_of(Array)
      data.should have(10).items
      data[0][:entries].should == 123000
      data[0][:policy][:web_url].should == "https://www.gov.uk/government/policies/sample-policy"
      data[0][:policy][:title].should == "Sample Policy"
      data[0][:policy][:organisations].should == [{abbreviation: "MOD", name: "Ministry of defence"}]
      data[0][:policy][:updated_at].should == "2012-12-19T02:00:00+00:00"
    end

    it "should return a 500 if there is no joined policy" do
      9.times { |n| FactoryGirl.create :policy_entries, entries: n }

      FactoryGirl.create :policy_entries,
                         entries: 123000,
                         slug: "sample-policy",
                         collected_at: DateTime.parse("2012-12-20T01:00:00+00:00")

      Policy.destroy

      get "/entries/weekly/policies"

      last_response.should_not be_ok
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

    it "should return the TOP ten policies for last week" do
      last_sunday = DateUtils.sunday_before(DateTime.now)
      15.times do |n|
        params = {
          entries: (n+2) * 1000,
          start_at: last_sunday - 14,
          end_at: last_sunday - 7
        }
        FactoryGirl.create :policy_entries, params
      end
      15.times do |n|
        params = {
          entries: (n+1) * 1000,
          start_at: last_sunday - 7,
          end_at: last_sunday
        }
        FactoryGirl.create :policy_entries, params
      end

      get "/entries/weekly/policies"

      json_response = JSON.parse(last_response.body, symbolize_names: true)
      details = json_response[:details]
      result = details[:data]

      details[:start_at].should == (last_sunday - 7).strftime
      details[:end_at].should == last_sunday.strftime

      result.should have(10).items
      result.first[:entries].should == 15000
      result.last[:entries].should == 6000
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