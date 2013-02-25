require_relative "../spec_helper"
require_relative "../../lib/model/content_engagement_visits"
require_relative "../../lib/presenter/content_engagement_detail_presenter"

describe ContentEngagementDetailPresenter do
  it "should create a content engagement detail response from a list of content engagement visits" do
    list_of_content_engagement_visits = [
      FactoryGirl.create(:content_engagement_visits_with_artefact),
      FactoryGirl.create(:content_engagement_visits_with_artefact)
    ]

    response = ContentEngagementDetailPresenter.new.present(list_of_content_engagement_visits)

    response[:details][:data].should have(2).items
  end

  it "should create a content engagement detail response with correct data format" do
    list_of_content_engagement_visits = [
      FactoryGirl.create(:content_engagement_visits_with_artefact, :slug => "foo"),
      FactoryGirl.create(:content_engagement_visits_with_artefact, :slug => "bar")
    ]

    response = ContentEngagementDetailPresenter.new.present(list_of_content_engagement_visits)

    response[:details][:data].first[:format].should == "guide"
    response[:details][:data].first[:slug].should == "foo"
    response[:details][:data].first[:entries].should == 10000
    response[:details][:data].first[:successes].should == 5000
  end

  it "should create a content engagement detail response with standard metadata" do
    list_of_content_engagement_visits = [
      FactoryGirl.create(:content_engagement_visits_with_artefact)
    ]

    response = ContentEngagementDetailPresenter.new.present(list_of_content_engagement_visits)

    response[:details][:start_at].should == "2013-01-13T00:00:00+00:00"
    response[:details][:end_at].should == "2013-01-20T00:00:00+00:00"
    response[:details][:source].should == ["Google Analytics"]
    response[:updated_at].should == "2013-01-21T00:00:00+00:00"
  end

  it "should normally mark response as ok" do
    list_of_content_engagement_visits = [
      FactoryGirl.create(:content_engagement_visits_with_artefact)
    ]

    response = ContentEngagementDetailPresenter.new.present(list_of_content_engagement_visits)

    response[:response_info][:status].should == "ok"
  end

  it "should fail if start_at vary among given objects" do
    list_of_content_engagement_visits = [
        FactoryGirl.create(:content_engagement_visits_with_artefact,
                          :start_at => Date.new(2012, 7, 1), :end_at => Date.new(2012, 7, 15)),
        FactoryGirl.create(:content_engagement_visits_with_artefact,
                          :start_at => Date.new(2012, 7, 8), :end_at => Date.new(2012, 7, 15)),
    ]

    lambda { ContentEngagementDetailPresenter.new.present(list_of_content_engagement_visits) }.should raise_exception
  end

  it "should fail if end_at vary among given objects" do
    list_of_content_engagement_visits = [
        FactoryGirl.create(:content_engagement_visits_with_artefact,
                          :start_at => Date.new(2012, 7, 1), :end_at => Date.new(2012, 7, 7)),
        FactoryGirl.create(:content_engagement_visits_with_artefact,
                          :start_at => Date.new(2012, 7, 1), :end_at => Date.new(2012, 7, 15)),
    ]

    lambda { ContentEngagementDetailPresenter.new.present(list_of_content_engagement_visits) }.should raise_exception
  end

  it "should not fail if artefacts with no associated visits are in the result set" do
    engagement = FactoryGirl.create(:content_engagement_visits_with_artefact,
                                           :start_at => Date.new(2012, 7, 1), :end_at => Date.new(2012, 7, 7))
    engagement_with_no_visits =
      FactoryGirl.create(:content_engagement_visits_with_artefact,
                         :start_at => Date.new(2012, 7, 1), :end_at => Date.new(2012, 7, 7),
                         :entries => 0, :successes => 0)
    list_of_content_engagement_visits = [engagement, engagement_with_no_visits]

    lambda { ContentEngagementDetailPresenter.new.present(list_of_content_engagement_visits) }.should_not raise_exception
  end

  it "should return entries and successes as nil if entries are less than significance threshold (1000)" do
    list_of_content_engagement_visits = [
      FactoryGirl.create(:content_engagement_visits_with_artefact, :slug => "foo",
                         :entries => 999, :successes => 999),
      FactoryGirl.create(:content_engagement_visits_with_artefact, :slug => "bar",
                         :entries => 2000, :successes => 50)
    ]

    response = ContentEngagementDetailPresenter.new.present(list_of_content_engagement_visits)

    response[:details][:data].first[:slug].should == "foo"
    response[:details][:data].first[:entries].should == nil
    response[:details][:data].first[:successes].should == nil

    response[:details][:data][1][:slug].should == "bar"
    response[:details][:data][1][:entries].should == 2000
    response[:details][:data][1][:successes].should == 50
  end
end