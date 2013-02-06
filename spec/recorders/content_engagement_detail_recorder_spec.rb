require_relative "../spec_helper"
require_relative "../../lib/recorder"
require_relative "../../lib/model/content_engagement_visits"

describe "ContentEngagementDetailRecorder" do
  before(:each) do
    @message = {
      :envelope => {
        :collected_at => DateTime.now.strftime,
        :collector    => "Google Analytics",
        :_routing_key => "google_analytics.insidegov.content_engagement.weekly"
      },
      :payload => {
        :start_at => "2011-03-28T00:00:00",
        :end_at => "2011-04-04T00:00:00",
        :value => {
          :entries => 700,
          :format => "policy",
          :site => "insidegov",
          :slug => "/government/policies/some-policy",
          :successes => 250,
        }
      }
    }
    @recorder = Recorder.new
  end

  it "should store weekly content engagement entries when processing message" do
    @recorder.update_message(@message)
  
    ContentEngagementVisits.all.should_not be_empty
    item = ContentEngagementVisits.first
    item.entries.should == 700
    item.format.should == "policy"
    item.slug.should == "/government/policies/some-policy"
    item.successes.should == 250
    item.start_at.should == DateTime.new(2011, 3, 28)
    item.end_at.should == DateTime.new(2011, 4, 4)
  end
end
