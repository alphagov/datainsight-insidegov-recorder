require_relative "../spec_helper"
require_relative "../../lib/model/content_engagement_visits"

describe ContentEngagementVisits do
  describe "last_week_visits" do
    it "should return visits for the available week" do
      FactoryGirl.create(:content_engagement_visits_with_artefact, slug: "/foo",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))
      FactoryGirl.create(:content_engagement_visits_with_artefact, slug: "/bar",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))

      older_item = FactoryGirl.create(:content_engagement_visits, slug: "/alfa",
                                      start_at: DateTime.new(2012, 6, 24), end_at: DateTime.new(2012, 7, 1))

      content_engagement_visits = ContentEngagementVisits.last_week_visits

      content_engagement_visits.should have(2).items
      content_engagement_visits.should_not include(older_item)
    end

    it "should return engagement together with artefact details" do
      FactoryGirl.create(:content_engagement_visits_with_artefact, slug: "/foo",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))
      FactoryGirl.create(:content_engagement_visits_with_artefact, slug: "/bar",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))

      engagement = ContentEngagementVisits.last_week_visits

      engagement.should have(2).items
      engagement.first.artefact.should_not be_nil
    end

    it "should not return engagement that does not have a matching artefact" do
      FactoryGirl.create(:content_engagement_visits, slug: "/foo",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))
      FactoryGirl.create(:content_engagement_visits_with_artefact, slug: "/bar",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))

      engagement = ContentEngagementVisits.last_week_visits

      engagement.should have(1).item
      engagement.first.slug.should == "/bar"
    end

    it "should return artefacts even if they do not have matching engagement" do
      FactoryGirl.create(:content_engagement_visits_with_artefact, slug: "/foo",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))
      FactoryGirl.create(:artefact, slug: "/bar")

      engagement = ContentEngagementVisits.last_week_visits

      engagement.should have(2).items
    end

    it "should not return artefacts that have been disabled" do
      engagement = FactoryGirl.create(:content_engagement_visits_with_artefact, slug: "/foo",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))
      FactoryGirl.create(:content_engagement_visits_with_artefact, slug: "/bar",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))
      engagement.artefact.disabled = true
      engagement.artefact.save

      engagement = ContentEngagementVisits.last_week_visits

      engagement.should have(1).item
    end
  end

  describe "update_from_message" do
    before(:each) do
      @message = {
        :envelope => {
          :collected_at => DateTime.new(2013, 2, 27, 11, 11, 0, 0).strftime,
          :collector    => "Google Analytics",
          :_routing_key => "google_analytics.insidegov.content_engagement.weekly",
        },
        :payload => {
          :start_at => DateTime.new(2013, 2, 18, 0, 0, 0, 0).strftime,
          :end_at => DateTime.new(2013, 2, 25, 0, 0, 0, 0).strftime,
          :value => {
            :slug => "foo-bar",
            :entries => 1000,
            :successes => 500,
            :format => "policy",
          },
        },
      }
    end

    it "should insert a new item" do
      ContentEngagementVisits.update_from_message(@message)
      ContentEngagementVisits.all.should have(1).item

      content_engagement_visits = ContentEngagementVisits.first
      content_engagement_visits.slug.should == "foo-bar"
      content_engagement_visits.source.should == "Google Analytics"
      content_engagement_visits.entries.should == 1000
      content_engagement_visits.successes.should == 500
      content_engagement_visits.format.should == "policy"
      content_engagement_visits.start_at.should == DateTime.new(2013, 2, 18, 0, 0, 0)
      content_engagement_visits.end_at.should == DateTime.new(2013, 2, 25, 0, 0, 0)
    end

    it "should update an existing item" do
      FactoryGirl.create(:content_engagement_visits,
        :slug => "foo-bar",
        :format => "policy",
        :start_at => DateTime.new(2013, 2, 18, 0, 0, 0).strftime,
        :end_at => DateTime.new(2013, 2, 25, 0, 0, 0).strftime,
        :entries => 0,
        :successes => 0,
      )

      ContentEngagementVisits.update_from_message(@message)
      ContentEngagementVisits.all.should have(1).item

      content_engagement_visits = ContentEngagementVisits.first
      content_engagement_visits.entries.should == 1000
      content_engagement_visits.successes.should == 500
    end

    it "should downcase the slug" do
      @message[:payload][:value][:slug] = "FOO-BAR"

      ContentEngagementVisits.update_from_message(@message)

      content_engagement_visits = ContentEngagementVisits.first
      content_engagement_visits.slug.should == "foo-bar"
    end
  end

  describe "validation" do
    it "should not allow nil slug" do
      content_engagement_visits = FactoryGirl.build(:content_engagement_visits, slug: nil)
      content_engagement_visits.should_not be_valid
    end

    it "should not allow nil format" do
      content_engagement_visits = FactoryGirl.build(:content_engagement_visits, format: nil)
      content_engagement_visits.should_not be_valid
    end

    it "should not allow nil entries" do
      content_engagement_visits = FactoryGirl.build(:content_engagement_visits, entries: nil)
      content_engagement_visits.should_not be_valid
    end

    it "should not allow negative entries" do
      content_engagement_visits = FactoryGirl.build(:content_engagement_visits, entries: -2)
      content_engagement_visits.should_not be_valid
    end

    it "should not allow nil successes" do
      content_engagement_visits = FactoryGirl.build(:content_engagement_visits, successes: nil)
      content_engagement_visits.should_not be_valid
    end

    it "should not allow negative successes" do
      content_engagement_visits = FactoryGirl.build(:content_engagement_visits, successes: -1)
      content_engagement_visits.should_not be_valid
    end
  end
end
