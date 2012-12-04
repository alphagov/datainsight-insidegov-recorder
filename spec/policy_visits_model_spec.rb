require "spec_helper"

describe "the policy_visits model" do
  it "should validate visits correctly (only integers)" do
    policy_visits_record = PolicyVisits.new(visits: "test")

    policy_visits_record.valid?.should == false

    policy_visits_record.errors[:visits].first.should == "Visits must be an integer"
  end

  it "should validate visits correctly (required field)" do
    policy_visits_record = PolicyVisits.new(slug: "test")

    policy_visits_record.valid?.should == false

    policy_visits_record.errors[:visits].first.should == "Visits must not be blank"
  end

  it "should validate visits correctly (positive)" do
    policy_visits_record = PolicyVisits.new(visits: -6, slug: "foobar")

    policy_visits_record.valid?.should == false

    policy_visits_record.errors[:visits].first.should == "It must be greater than or equal to 0"
  end

  it "should validate slug correctly (required field)" do
    policy_visits_record = PolicyVisits.new(visits: 1)

    policy_visits_record.valid?.should == false

    policy_visits_record.errors[:slug].first.should == "Slug must not be blank"
  end

  it "should return know if it has metadata" do
    policy_visits_record = PolicyVisits.new(visits: 1, slug: "foo", policy: {})
    policy_visits_record_with_no_metadata = PolicyVisits.new(visits: 1, slug: "foo", policy: nil)

    policy_visits_record.has_metadata?.should == true
    policy_visits_record_with_no_metadata.has_metadata?.should == false
  end

end