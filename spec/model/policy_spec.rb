require_relative "../spec_helper"

describe "policy (metadata) model" do
  describe "update from message" do
    before(:each) do
      @message = {
        :envelope => {
          :collected_at => DateTime.new(2012, 12, 12, 11, 11, 0, 0).strftime,
          :collector    => "InsideGov",
          :_routing_key => "inside_gov.policies"
        },
        :payload => {
          :title         => "Policy title",
          :url           => "/government/policies/foo-bar",
          :organisations => [{"abbreviation" => "MOD", "name" => "Ministry of defence"}],
          :updated_at    => DateTime.new(2012, 12, 12, 12, 12, 0, 0).strftime
        }
      }
    end
    it "should insert a new policy" do
      Policy.update_from_message(@message)
      Policy.all.should have(1).item

      policy = Policy.first
      policy.slug.should == "foo-bar"
      policy.title.should == "Policy title"
      policy.organisations.should == '[{"abbreviation":"MOD","name":"Ministry of defence"}]'
      policy.source.should == "InsideGov"
      policy.policy_updated_at.should == DateTime.new(2012, 12, 12, 12, 12, 0, 0)
      policy.collected_at.should == DateTime.new(2012 ,12, 12, 11, 11, 0, 0)

    end
    
    it "should update an existing policy" do
      Policy.create(
        :title => "New title",
        :slug  => "foo-bar",
        :organisations => [{"abbreviation" => "NEW", "name" => "Ministry of new"}],
        :policy_updated_at => DateTime.new(2012, 12, 12, 11, 11, 0, 0),
        :collected_at => DateTime.new(2012, 12, 12, 10, 10, 0, 0),
        :source => "InsideGov"
      )

      Policy.update_from_message(@message)
      Policy.all.should have(1).item

      policy = Policy.first
      policy.slug.should == "foo-bar"
      policy.title.should == "Policy title"
      policy.organisations.should == '[{"abbreviation":"MOD","name":"Ministry of defence"}]'
      policy.source.should == "InsideGov"
      policy.policy_updated_at.should == DateTime.new(2012, 12, 12, 12, 12, 0, 0)
      policy.collected_at.should == DateTime.new(2012 ,12, 12, 11, 11, 0, 0)
    end

    it "should re-enable policies on update" do
      slug = "test-policy"
      FactoryGirl.create(:policy, slug: slug, disabled: true)

      @message[:payload][:url] = "/government/policies/#{slug}"

      Policy.update_from_message(@message)

      Policy.first(slug: slug).disabled.should == false
    end

    it "strip the leading '/government/policies' of the slug" do
      @message[:payload][:url] = "/government/policies/foo-bar"

      Policy.update_from_message(@message)

      policy = Policy.first
      policy.slug.should == "foo-bar"
    end

    it "should allow updated_at to not be provided" do
      @message[:payload].delete(:updated_at)

      Policy.update_from_message(@message)

      Policy.all.should have(1).item
    end

    describe "failure" do
      it "should fail if no title is provided" do
        @message[:payload].delete(:title)

        lambda { Policy.update_from_message(@message) }.should raise_error
      end

      it "should fail if no organisations are provided" do
        @message[:payload].delete(:organisations)

        lambda { Policy.update_from_message(@message) }.should raise_error
      end

      it "should fail if no collected_at is provided" do
        @message[:envelope].delete(:collected_at)

        lambda { Policy.update_from_message(@message) }.should raise_error
      end
    end
  end

  describe "validation" do
    describe "required fields" do
      it "should require a slug" do
        policy = Policy.new(
                  title: "test",
                  source: "source",
                  organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
                  policy_updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
                  collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        policy.valid?.should == false
        policy.errors[:slug].first.should == "Slug must not be blank"
      end

      it "should require a title" do
        policy = Policy.new(
                  slug: "test",
                  source: "source",
                  organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
                  policy_updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
                  collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        policy.valid?.should == false
        policy.errors[:title].first.should == "Title must not be blank"
      end

      it "should require an organisations" do
        policy = Policy.new(
                  slug: "test",
                  title: "test",
                  source: "source",
                  policy_updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
                  collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        policy.valid?.should == false
        policy.errors[:organisations].first.should == "Organisations must not be blank"
      end

      it "should require not an policy_updated_at" do
        policy = Policy.new(
                  slug: "test",
                  title: "test",
                  source: "source",
                  organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
                  collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        policy.valid?.should == true
      end

      it "should require a collected_at" do
        policy = Policy.new(
                  slug: "test",
                  title: "test",
                  source: "source",
                  organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
                  policy_updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        policy.valid?.should == false
        policy.errors[:collected_at].first.should == "Collected at must not be blank"
      end

    end

    it "should require a source" do
        policy = Policy.new(
                  slug: "test",
                  title: "test",
                  organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
                  policy_updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
                  collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        policy.valid?.should == false
        policy.errors[:source].first.should == "Source must not be blank"

    end

    it "should validate policy_updated_at correctly (must be DateTime)" do
      policy = Policy.new(
                slug: "test",
                title: "test",
                source: "source",
                organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
                policy_updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
                collected_at: "not_a_date_time")

      policy.valid?.should == false
      policy.errors[:collected_at].first.should == "Collected at must be of type DateTime"
    end

  end
end