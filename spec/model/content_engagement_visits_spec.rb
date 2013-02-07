describe ContentEngagementVisits do
  describe "last_week_visits" do
    it "should return visits for the available week" do
      FactoryGirl.create(:content_engagement_visits, slug: "/foo",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))
      FactoryGirl.create(:content_engagement_visits, slug: "/bar",
                         start_at: DateTime.new(2012, 7, 1), end_at: DateTime.new(2012, 7, 8))

      older_item = FactoryGirl.create(:content_engagement_visits, slug: "/alfa",
                                      start_at: DateTime.new(2012, 6, 24), end_at: DateTime.new(2012, 7, 1))

      content_engagement_visits = ContentEngagementVisits.last_week_visits

      content_engagement_visits.should have(2).items
      content_engagement_visits.should_not include(older_item)
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
