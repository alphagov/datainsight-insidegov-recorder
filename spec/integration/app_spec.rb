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
      start_at ||= last_sunday_of(Date.today.to_datetime - (24 * weeks))
      end_at ||= last_saturday_of(Date.today.to_datetime)
      end_date_of_a_first_week = Date.today.to_datetime - (23 * weeks)

      create_measurements(start_at, end_at, metric: "visitors", value: 500)
      get "/visitors/weekly"

      one_minute = Rational(1, 24*60)

      last_response.content_type.should start_with("application/json")
      json_response = JSON.parse(last_response.body, symbolize_names: true)
      DateTime.parse(json_response[:updated_at]).should be_within(one_minute).of(DateTime.now)
      json_response[:response_info].should == {status: "ok"}
      json_response[:id].should == "/visitors/weekly"
      json_response[:web_url].should == ""
      json_response[:details][:data].should have(24).items
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

    after(:each) do
      Policy.destroy
      PolicyVisits.destroy
      FactoryGirl.reload
    end

    it "should serve up a json response" do
      4.times { |n| FactoryGirl.create :policy_visits, visits: n }

      FactoryGirl.create :policy,
                         slug: "/government/policy/sample-policy",
                         title: "Sample Policy",
                         department: "MOD",
                         collected_at: DateTime.parse("2012-12-20T02:00:00+00:00")

      FactoryGirl.create :policy_visits,
                         visits: 123000,
                         slug: "/government/policy/sample-policy",
                         collected_at: DateTime.parse("2012-12-20T01:00:00+00:00")

      get "/visits/weekly/policies"

      last_response.should be_ok
      last_response.content_type.should start_with("application/json")

      json_response = JSON.parse(last_response.body, symbolize_names: true)
      json_response[:response_info].should == {status: "ok"}
      json_response[:updated_at].should == "2012-12-20T02:00:00+00:00"

      json_response[:details][:data].should be_an_instance_of(Array)
      json_response[:details][:data].should have(5).items
      json_response[:details][:data][0][:visits].should == 123000
      json_response[:details][:data][0][:policy][:web_url].should == "https://www.gov.uk/government/policy/sample-policy"
      json_response[:details][:data][0][:policy][:title].should == "Sample Policy"
      json_response[:details][:data][0][:policy][:department].should == "MOD"
      json_response[:details][:data][0][:policy][:updated_at].should == "2012-12-20T02:00:00+00:00"
    end

    it "should return a response with five policies" do
      10.times { FactoryGirl.create :policy_visits }

      get "/visits/weekly/policies"

      last_response.should be_ok
      last_response.content_type.should start_with("application/json")

      json_response = JSON.parse(last_response.body, symbolize_names: true)
      result = json_response[:details][:data]
      result.should be_an_instance_of(Array)
      result.should have(5).items
    end

    it "should return the TOP five policies" do
      10.times { |n| FactoryGirl.create :policy_visits, visits: (n+1)*100000 }

      get "/visits/weekly/policies"

      json_response = JSON.parse(last_response.body, symbolize_names: true)
      result = json_response[:details][:data]

      result.should have(5).items
      result.all? { |data| data[:visits] >= 600000 }.should be_true
    end

    it "should error if there are not five policies to return" do
      4.times { FactoryGirl.create :policy_visits }

      get "/visits/weekly/policies"

      last_response.status.should == 503
    end

    it "should deal with the case where there is missing meta-data for the top five policies" do
      3.times { FactoryGirl.create :policy_visits, policy: nil }
      2.times { FactoryGirl.create :policy_visits }

      get "/visits/weekly/policies"

      last_response.status.should == 503

    end

  end
end