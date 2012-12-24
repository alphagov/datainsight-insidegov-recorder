describe "policy (metadata) model" do
  describe "validation" do
    describe "required fields" do

      it "should reuqire a slug" do
        policy_record = Policy.new(title: "test",
                                   department: "the department of test",
                                   organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
                                   updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
                                   collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        policy_record.valid?.should == false
        policy_record.errors[:slug].first.should == "Slug must not be blank"
      end

      it "should require a title" do
        policy_record = Policy.new(slug: "test",
                                   department: "the department of test",
                                   organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
                                   updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
                                   collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        policy_record.valid?.should == false
        policy_record.errors[:title].first.should == "Title must not be blank"
      end

      it "should require a department" do
        policy_record = Policy.new(slug: "test",
                                   title: "test",
                                   organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
                                   updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
                                   collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        policy_record.valid?.should == false
        policy_record.errors[:department].first.should == "Department must not be blank"
      end
      
      it "should require an organisations" do
        policy_record = Policy.new(slug: "test",
                                   title: "test",
                                   department: "the department of test",
                                   updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
                                   collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        policy_record.valid?.should == false
        policy_record.errors[:organisations].first.should == "Organisations must not be blank"
      end

      it "should require an updated_at" do
        policy_record = Policy.new(slug: "test",
                                   title: "test",
                                   department: "the department of test",
                                   organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
                                   collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        policy_record.valid?.should == false
        policy_record.errors[:updated_at].first.should == "Updated at must not be blank"
      end

      it "should require a collected_at" do
        policy_record = Policy.new(slug: "test",
                                   title: "test",
                                   department: "the department of test",
                                   organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
                                   updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        policy_record.valid?.should == false
        policy_record.errors[:collected_at].first.should == "Collected at must not be blank"
      end

    end

    it "should validate updated_at correctly (must be DateTime)" do
      policy_record = Policy.new(slug: "test",
                                 title: "test",
                                 department: "the department of test",
                                 organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
                                 updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
                                 collected_at: "not_a_date_time")

      policy_record.valid?.should == false
      policy_record.errors[:collected_at].first.should == "Collected at must be of type DateTime"
    end
  end
end