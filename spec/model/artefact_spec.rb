require_relative "../../lib/model/artefact"
require_relative "../spec_helper"

describe Artefact do
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
          :type          => "policy",
          :url           => "/government/policies/foo-bar",
          :organisations => [{"abbreviation" => "MOD", "name" => "Ministry of defence"}],
          :updated_at    => DateTime.new(2012, 12, 12, 12, 12, 0, 0).strftime
        }
      }
    end

    it "should insert a new artefact" do
      Artefact.update_from_message(@message)
      Artefact.all.should have(1).item

      artefact = Artefact.first
      artefact.slug.should == "foo-bar"
      artefact.format.should == "policy"
      artefact.title.should == "Policy title"
      artefact.organisations.should == '[{"abbreviation":"MOD","name":"Ministry of defence"}]'
      artefact.source.should == "InsideGov"
      artefact.artefact_updated_at.should == DateTime.new(2012, 12, 12, 12, 12, 0, 0)
      artefact.collected_at.should == DateTime.new(2012, 12, 12, 11, 11, 0, 0)
    end

    it "should update an existing artefact" do
      Artefact.create(
        title: "Old title",
        slug: "foo-bar",
        format: "policy",
        url: "foo/bar/monkey",
        source: "InsideGov",
        organisations: [{"abbreviation" => "NEW", "name" => "Ministry of new"}].to_json,
        artefact_updated_at: DateTime.new(2012, 12, 12, 11, 11, 0, 0),
        collected_at: DateTime.new(2012, 12, 12, 10, 10, 0, 0),
      )

      Artefact.update_from_message(@message)
      Artefact.all.should have(1).item

      artefact = Artefact.first
      artefact.slug.should == "foo-bar"
      artefact.format.should == "policy"
      artefact.title.should == "Policy title"
      artefact.url.should == "/government/policies/foo-bar"
      artefact.organisations.should == '[{"abbreviation":"MOD","name":"Ministry of defence"}]'
      artefact.source.should == "InsideGov"
      artefact.artefact_updated_at.should == DateTime.new(2012, 12, 12, 12, 12, 0, 0)
      artefact.collected_at.should == DateTime.new(2012 ,12, 12, 11, 11, 0, 0)
    end

    it "should only update if both slug and format match" do
      Artefact.create(
        title: "Old title",
        slug: "foo-bar",
        format: "news",
        url: "foo/bar/monkey",
        source: "InsideGov",
        organisations: [{"abbreviation" => "NEW", "name" => "Ministry of new"}].to_json,
        artefact_updated_at: DateTime.new(2012, 12, 12, 11, 11, 0, 0),
        collected_at: DateTime.new(2012, 12, 12, 10, 10, 0, 0),
      )

      Artefact.update_from_message(@message)
      Artefact.all.should have(2).item
    end

    it "should re-enable artefacts on update" do
      slug = "test-policy"
      FactoryGirl.create(:artefact,
         slug: slug,
         disabled: true
      )

      @message[:payload][:url] = "/government/policies/#{slug}"

      Artefact.update_from_message(@message)

      Artefact.first.disabled.should == false
    end

    it "should strip the leading two parts of the slug" do
      @message[:payload][:url] = "/government/policies/foo-bar"

      Artefact.update_from_message(@message)

      Artefact.first.slug.should == "foo-bar"
    end

    it "should strip the leading path parts regardless of case" do
      @message[:payload][:url] = "/GOVERNMENT/POLICIES/foo-bar"

      Artefact.update_from_message(@message)

      Artefact.first.slug.should == "foo-bar"
    end

    it "should downcase the slug" do
      @message[:payload][:url] = "/GOVERNMENT/POLICIES/FOO-BAR"

      Artefact.update_from_message(@message)

      Artefact.first.slug.should == "foo-bar"
    end

    it "should convert news_article to news" do
      @message[:payload][:type] = "news_article"

      Artefact.update_from_message(@message)

      Artefact.first.format.should == "news"
    end
  end

  describe "validation" do
    describe "required fields" do
      it "should require a slug" do
        artefact = Artefact.new(
          title: "test",
          source: "source",
          organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
          artefact_updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
          collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        artefact.valid?.should == false
        artefact.errors[:slug].first.should == "Slug must not be blank"
      end

      it "should require a title" do
        artefact = Artefact.new(
          slug: "test",
          source: "source",
          organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
          artefact_updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
          collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        artefact.valid?.should == false
        artefact.errors[:title].first.should == "Title must not be blank"
      end

      it "should require an organisations" do
        artefact = Artefact.new(
          slug: "test",
          title: "test",
          source: "source",
          artefact_updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
          collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        artefact.valid?.should == false
        artefact.errors[:organisations].first.should == "Organisations must not be blank"
      end

      it "should require an artefact_updated_at" do
        artefact = Artefact.new(
          slug: "test",
          title: "test",
          source: "source",
          organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
          collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        artefact.valid?.should == false
        artefact.errors[:artefact_updated_at].first.should == "Artefact updated at must not be blank"
      end

      it "should require a collected_at" do
        artefact = Artefact.new(
          slug: "test",
          title: "test",
          source: "source",
          organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
          artefact_updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

        artefact.valid?.should == false
        artefact.errors[:collected_at].first.should == "Collected at must not be blank"
      end

    end

    it "should require a source" do
      artefact = Artefact.new(
        slug: "test",
        title: "test",
        organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
        artefact_updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
        collected_at: DateTime.parse("2012-11-19T16:00:07+00:00"))

      artefact.valid?.should == false
      artefact.errors[:source].first.should == "Source must not be blank"

    end

    it "should validate artefact_updated_at correctly (must be DateTime)" do
      artefact = Artefact.new(
        slug: "test",
        title: "test",
        source: "source",
        organisations: '[{"abbreviation":"MOD","name":"Ministry of Defence"}]',
        artefact_updated_at: DateTime.parse("2012-11-19T16:00:07+00:00"),
        collected_at: "not_a_date_time")

      artefact.valid?.should == false
      artefact.errors[:collected_at].first.should == "Collected at must be of type DateTime"
    end
  end

end