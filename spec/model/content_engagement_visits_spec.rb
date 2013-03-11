require_relative "../spec_helper"
require_relative "../../lib/model/content_engagement_visits"

describe ContentEngagementVisits do
  describe "last_week_visits" do
    it "should return visits for the available week" do
      FactoryGirl.create(:content_engagement_visits_with_artefact, format: "policy", slug: "/foo",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8), entries: 1)
      FactoryGirl.create(:content_engagement_visits_with_artefact, format: "policy", slug: "/bar",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8), entries: 2)

      older_item = FactoryGirl.create(:content_engagement_visits, format: "policy", slug: "/alfa",
                                      start_at: DateTime.new(2012, 6, 24), end_at: DateTime.new(2012, 7, 1),
                                      entries: 3)

      content_engagement_visits = ContentEngagementVisits.last_week_visits

      content_engagement_visits.should have(2).items
      content_engagement_visits.map(&:entries).should == [1, 2]
      content_engagement_visits.should_not include(older_item)
    end

    it "should return engagement together with artefact details" do
      FactoryGirl.create(:content_engagement_visits_with_artefact, format: "policy", slug: "/foo",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8), :entries => 9)
      FactoryGirl.create(:content_engagement_visits_with_artefact, format: "policy", slug: "/bar",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8), :entries => 21)

      engagement = ContentEngagementVisits.last_week_visits

      engagement.should have(2).items
      engagement.map(&:entries).should == [9, 21]
      engagement.first.artefact.should_not be_nil
    end

    it "should not return engagement that does not have a matching artefact" do
      FactoryGirl.create(:content_engagement_visits, format: "policy", slug: "/foo",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8), :entries => 15)
      FactoryGirl.create(:content_engagement_visits, format: "policy", slug: "/bar",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8), :entries => 64)
      FactoryGirl.create(:artefact, format: "policy", slug: "/bar")

      engagement = ContentEngagementVisits.last_week_visits

      engagement.should have(1).item
      engagement.map(&:entries).should == [64]
      engagement.first.slug.should == "/bar"
    end

    it "should return artefacts even if they do not have matching engagement" do
      FactoryGirl.create(:content_engagement_visits_with_artefact, slug: "/foo", format: "policy",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8), :entries => 14)
      FactoryGirl.create(:artefact, slug: "/bar", format: "policy")

      engagement = ContentEngagementVisits.last_week_visits

      engagement.should have(2).items
      engagement.first.slug.should == "/foo"
      engagement.first.format.should == "policy"
      engagement[1].slug.should == "/bar"
      engagement[1].format.should == "policy"
      engagement.map(&:entries).should == [14, 0]
    end

    it "should not return artefacts that have been disabled" do
      engagement = FactoryGirl.create(:content_engagement_visits_with_artefact, slug: "/foo", format: "policy",
                                      start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8), entries: 47)
      FactoryGirl.create(:content_engagement_visits_with_artefact, slug: "/bar", format: "policy",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8), entries: 29)
      engagement.artefact.disabled = true
      engagement.artefact.save

      engagement = ContentEngagementVisits.last_week_visits

      engagement.should have(1).item
      engagement.map(&:entries).should == [29]
    end

    it "should not return news artefacts older than 2 months" do
      Timecop.freeze(DateTime.new(2012, 12, 21)) {
        news_artefact_older_than_2_months =
          FactoryGirl.create(:artefact, :format => "news", slug: "old-news", :artefact_updated_at => DateTime.new(2012, 10, 21))
        news_artefact_younger_than_2_months =
          FactoryGirl.create(:artefact, :format => "news", slug: "recent-news", :artefact_updated_at => DateTime.new(2012, 10, 22))

        engagement = ContentEngagementVisits.last_week_visits

        engagement.should have(1).item
        engagement[0].slug.should == "recent-news"
      }
    end

    it "should return news artefacts older than 2 months with more than 1000 visits" do
      Timecop.freeze(DateTime.new(2012, 12, 21)) {
        FactoryGirl.create(:artefact, slug: "old-with-few-visits", format: "news", :artefact_updated_at => DateTime.new(2012, 10, 21))
        FactoryGirl.create(:content_engagement_visits, slug: "old-with-few-visits", format: "news", entries: 1)

        FactoryGirl.create(:artefact, slug: "old-with-many-visits", format: "news", :artefact_updated_at => DateTime.new(2012, 10, 21))
        FactoryGirl.create(:content_engagement_visits, slug: "old-with-many-visits", format: "news", entries: 1001)

        engagement = ContentEngagementVisits.last_week_visits

        engagement.should have(1).item
        engagement[0].slug.should == "old-with-many-visits"
      }
    end

    it "should return policy artefacts older than 2 months" do
      Timecop.freeze(DateTime.new(2013, 2, 21)) {
        policy_artefact_older_than_2_months = FactoryGirl.create(
          :content_engagement_visits_with_artefact, slug: "/foo", format: "policy",
          start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2013, 1, 15), entries: 85)
        policy_artefact_older_than_2_months = FactoryGirl.create(
          :content_engagement_visits_with_artefact, slug: "/bar", format: "policy",
          start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8), entries: 50)

        engagement = ContentEngagementVisits.last_week_visits
        engagement.should have(2).item
        engagement.map(&:entries).should == [85, 50]
      }
    end

    it "should only return supported formats" do
      Timecop.freeze(DateTime.new(2013, 2, 21)) {
        FactoryGirl.create(
          :content_engagement_visits_with_artefact, slug: "/foo", format: "policy",
          start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2013, 1, 15), entries: 85)
        FactoryGirl.create(
          :content_engagement_visits_with_artefact, slug: "/bar", format: "speech",
          start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2013, 1, 15), entries: 50)

        engagement = ContentEngagementVisits.last_week_visits(%w(policy))
        engagement.should have(1).item
        engagement.first.format.should == "policy"
        engagement.map(&:entries).should == [85]
      }
    end

    it "should return only data for artefacts existing at the time of the last collection" do
      Timecop.freeze(DateTime.new(2013, 2, 21)) {
        existing_policy = FactoryGirl.create(:artefact, slug: "donald",  format: "policy", collected_at: DateTime.new(2013, 2, 20, 2, 10, 4))
        deleted_policy =  FactoryGirl.create(:artefact, slug: "huey", format: "policy", collected_at: DateTime.new(2013, 2, 19, 2, 10, 7))
        existing_news = FactoryGirl.create(:artefact, slug: "dewey",  format: "news", collected_at: DateTime.new(2013, 2, 20, 2, 10, 4))
        deleted_news  = FactoryGirl.create(:artefact, slug: "louie", format: "news", collected_at: DateTime.new(2013, 2, 19, 2, 10, 7))

        FactoryGirl.create(:content_engagement_visits, slug: existing_policy.slug, format: "policy", start_at: DateTime.new(2013, 2, 10), end_at: DateTime.new(2013, 2, 17), entries: 1500)
        FactoryGirl.create(:content_engagement_visits, slug: deleted_policy.slug,  format: "policy", start_at: DateTime.new(2013, 2, 10), end_at: DateTime.new(2013, 2, 17), entries: 1500)
        FactoryGirl.create(:content_engagement_visits, slug: existing_news.slug, format: "news", start_at: DateTime.new(2013, 2, 10), end_at: DateTime.new(2013, 2, 17), entries: 1500)
        FactoryGirl.create(:content_engagement_visits, slug: deleted_news.slug,  format: "news", start_at: DateTime.new(2013, 2, 10), end_at: DateTime.new(2013, 2, 17), entries: 1500)

        content_engagement_visits = ContentEngagementVisits.last_week_visits

        content_engagement_visits.find {|visits| visits.slug == "donald" }.should_not be_nil
        content_engagement_visits.find {|visits| visits.slug == "huey"}.should be_nil
        content_engagement_visits.find {|visits| visits.slug == "dewey"}.should_not be_nil
        content_engagement_visits.find {|visits| visits.slug == "louie"}.should be_nil
      }
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
