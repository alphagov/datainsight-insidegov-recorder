describe "policy (metadata) model" do
  it "should validate slug correctly (required)" do
    policy_record = Policy.new(title: "test",
                               department: "the department of test",
                               updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

    policy_record.valid?.should == false
    policy_record.errors[:slug].first.should == "Slug must not be blank"
  end

  it "should validate title correctly (required)" do
    policy_record = Policy.new(slug: "test",
                               department: "the department of test",
                               updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

    policy_record.valid?.should == false
    policy_record.errors[:title].first.should == "Title must not be blank"
  end

  it "should validate updated_at correctly (required)" do
    policy_record = Policy.new(slug: "test",
                               title: "test",
                               department: "the department of test")

    policy_record.valid?.should == false
    policy_record.errors[:updated_at].first.should == "Updated at must not be blank"
  end

  it "should validate updated_at correctly (must be DateTime)" do
    policy_record = Policy.new(slug: "test",
                               title: "test",
                               department: "the department of test",
                               updated_at: "not_a_date_time")

    policy_record.valid?.should == false
    policy_record.errors[:updated_at].first.should == "Updated at must be of type DateTime"
  end
end