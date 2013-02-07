require "spec_helper"
require_relative "../lib/content_engagement_presenter"

describe ContentEngagementPresenter do

  it "should create a content engagement response from a list of format visits" do
    list_of_format_visits = [FactoryGirl.build(:format_visits), FactoryGirl.build(:format_visits)]

    response = ContentEngagementPresenter.new.present(list_of_format_visits)

    response[:details][:data].should have(2).items
  end

  it "should include all sources without duplicates" do
    list_of_format_visits = [
        FactoryGirl.build(:format_visits, source: "source 1"),
        FactoryGirl.build(:format_visits, source: "source 1"),
        FactoryGirl.build(:format_visits, source: "source 2")
    ]

    response = ContentEngagementPresenter.new.present(list_of_format_visits)

    response[:details][:source].should have(2).items
    response[:details][:source].should include "source 1", "source 2"
  end

  it "should include the most recent collection date as update date" do
    list_of_format_visits = [
        FactoryGirl.build(:format_visits, collected_at: DateTime.new(2012, 12, 2, 12, 0, 0) ),
        FactoryGirl.build(:format_visits, collected_at: DateTime.new(2012, 12, 2, 12, 0, 10) ),
        FactoryGirl.build(:format_visits, collected_at: DateTime.new(2012, 12, 2, 12, 0, 5) ),
    ]

    response = ContentEngagementPresenter.new.present(list_of_format_visits)

    response[:updated_at].should == "2012-12-02T12:00:10+00:00"
  end

  it "should report percentage of success as 0 if both entries and successes are 0" do
    list_of_format_visits = [
      FactoryGirl.build(:format_visits, entries: 0, successes: 0)
    ]

    response = ContentEngagementPresenter.new.present(list_of_format_visits)
    response[:details][:data].first[:percentage_of_success].should == 0
  end

  it "should build an empty response if no visits are available" do
    response = ContentEngagementPresenter.new.present([])

    response[:details][:data].should == []
    response[:details][:source].should == []
    response[:updated_at].should be_nil
  end

end