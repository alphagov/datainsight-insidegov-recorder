require "spec_helper"

describe "the policy_entries model" do
  describe "validation" do
    it "should validate entries correctly (only integers)" do
      policy_visits_record = PolicyEntries.new(entries: "test")

      policy_visits_record.valid?.should == false

      policy_visits_record.errors[:entries].first.should == "Entries must be an integer"
    end

    it "should validate entries correctly (required field)" do
      policy_visits_record = PolicyEntries.new(slug: "test")

      policy_visits_record.valid?.should == false

      policy_visits_record.errors[:entries].first.should == "Entries must not be blank"
    end

    it "should validate entries correctly (positive)" do
      policy_visits_record = PolicyEntries.new(entries: -6, slug: "foobar")

      policy_visits_record.valid?.should == false

      policy_visits_record.errors[:entries].first.should == "It must be greater than or equal to 0"
    end

    it "should validate slug correctly (required field)" do
      policy_visits_record = PolicyEntries.new(entries: 1)

      policy_visits_record.valid?.should == false

      policy_visits_record.errors[:slug].first.should == "Slug must not be blank"
    end

    it "should return know if it has metadata" do
      policy_visits_record = PolicyEntries.new(entries: 1, slug: "foo", policy: {})
      policy_visits_record_with_no_metadata = PolicyEntries.new(entries: 1, slug: "foo", policy: nil)

      policy_visits_record.has_metadata?.should == true
      policy_visits_record_with_no_metadata.has_metadata?.should == false
    end
  end

  describe "top" do
    before(:each) do
      15.times { |n| FactoryGirl.create :policy_entries, entries: (n+1)*100000 }
    end

    it "should return the top 5 elements" do
      top_five = PolicyEntries.top(5)

      top_five.should have(5).items
    end

    it "should return the top 10 elements" do
      top_ten = PolicyEntries.top(10)

      top_ten.should have(10).items
    end
  end

  describe "policy join" do
    before(:each) do
      FactoryGirl.create :policy_entries, slug: "/my-slug"
      FactoryGirl.create :policy, slug: "/my-slug"
    end

    it "should return the joined policy" do
      policy_entries = PolicyEntries.first
      policy_entries.policy.should be_a(Policy)
      policy_entries.policy.slug.should == "/my-slug"
    end

    it "should return nil if no policy is" do
      Policy.destroy
      policy_entries = PolicyEntries.first
      policy_entries.policy.should be_nil
    end
  end
end