require_relative "../spec_helper"
require_relative "../../lib/recorders/policy_visits_recorder"
require_relative "../../lib/model/policy_visits"

describe "PolicyVisitsRecorder" do
  before(:each) do
    @message = {
      :envelope => {
        :collected_at => DateTime.now.strftime,
        :collector    => "Google Analytics",
        :_routing_key => "google_analytics.insidegov.policy_visits.weekly"
      },
      :payload => {
        :start_at => "2011-03-28T00:00:00",
        :end_at => "2011-04-04T00:00:00",
        :value => {
          :visits => 700,
          :slug => "/government/policies/some-policy"
        }
      }
    }
    @recorder = PolicyVisitsRecorder.new
  end

  after :each do
    PolicyVisits.destroy
  end

  it "should store weekly policy visits when processing drive message" do
    @recorder.update_message(@message)

    PolicyVisits.all.should_not be_empty
    item = PolicyVisits.first
    item.visits.should == 700
    item.start_at.should == DateTime.new(2011, 3, 28)
    item.end_at.should == DateTime.new(2011, 4, 4)
  end

  it "should store weekly data when processing analytics message" do
    @message[:payload][:value][:site] = "insidegov"
    @recorder.update_message(@message)

    PolicyVisits.all.should_not be_empty
    item = PolicyVisits.first
    item.visits.should == 700
    item.start_at.should == DateTime.new(2011, 3, 28)
    item.end_at.should == DateTime.new(2011, 4, 4)
  end

  it "should correctly handle end date over month boundaries" do
    @message[:payload][:start_at] = "2011-08-25T00:00:00"
    @message[:payload][:end_at] = "2011-09-01T00:00:00"
    @recorder.update_message(@message)
    item = PolicyVisits.first
    item.end_at.should == DateTime.new(2011, 9, 1)
  end

  it "should update existing measurements" do
    @recorder.update_message(@message)
    @message[:payload][:value][:visits] = 900
    @recorder.update_message(@message)
    PolicyVisits.all.length.should == 1
    PolicyVisits.first.visits.should == 900
  end

  describe "validation" do
    it "should fail if value is not present" do
      @message[:payload].delete(:value)

      lambda do
        @recorder.update_message(@message)
      end.should raise_error
    end

    it "should fail if value is not nil and cannot be parsed as a integer" do
      @message[:payload][:value] = "invalid"

      lambda do
        @recorder.update_message(@message)
      end.should raise_error
    end

    it "should allow nil as a value" do
      @message[:payload][:value][:visits] = nil

      lambda do
        @recorder.update_message(@message)
      end.should_not raise_error
    end

  end
end
