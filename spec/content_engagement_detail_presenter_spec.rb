require "spec_helper"
require_relative "../lib/model/content_engagement_visits"
require_relative "../lib/content_engagement_detail_presenter"

describe ContentEngagementDetailPresenter do
  it "should create a content engagement detail response from a list of content engagement visits" do
    list_of_content_engagement_visits = [FactoryGirl.build(:content_engagement_visits), FactoryGirl.build(:content_engagement_visits)]

    response = ContentEngagementDetailPresenter.new.present(list_of_content_engagement_visits)

    response[:details][:data].should have(2).items
  end

  it "should create a content engagement detail response with correct data format" do
    list_of_content_engagement_visits = [FactoryGirl.build(:content_engagement_visits), FactoryGirl.build(:content_engagement_visits)]

    response = ContentEngagementDetailPresenter.new.present(list_of_content_engagement_visits)

    response[:details][:data].first[:format].should == "guide"
    response[:details][:data].first[:slug].should == "apply-for-visa"
    response[:details][:data].first[:entries].should == 10000
    response[:details][:data].first[:successes].should == 5000
  end

  it "should create a content engagement detail response with standard metadata" do
    list_of_content_engagement_visits = [
      FactoryGirl.build(:content_engagement_visits)
    ]

    response = ContentEngagementDetailPresenter.new.present(list_of_content_engagement_visits)

    response[:details][:start_at].should == "2013-01-13T00:00:00+00:00"
    response[:details][:end_at].should == "2013-01-20T00:00:00+00:00"
    response[:details][:source].should == ["Google Analytics"]
    response[:updated_at].should == "2013-01-21T00:00:00+00:00"
  end

  it "should normally mark response as ok" do
    list_of_content_engagement_visits = [
      FactoryGirl.build(:content_engagement_visits)
    ]

    response = ContentEngagementDetailPresenter.new.present(list_of_content_engagement_visits)

    response[:response_info][:status].should == "ok"
  end
end