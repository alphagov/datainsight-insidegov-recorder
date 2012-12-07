require "spec_helper"

describe "the policy_entries model" do
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