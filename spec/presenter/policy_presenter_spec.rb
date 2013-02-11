require_relative "../spec_helper"
require_relative "../../lib/presenter/policy_presenter"

describe PolicyPresenter do
  before(:each) do
    @presenter = PolicyPresenter.new
  end
  it "should create a valid response from a list of PolicyEntries objects" do
    policies = [FactoryGirl.build(:policy_entries), FactoryGirl.build(:policy_entries)]

    response = @presenter.present(policies)

    date_time_pattern = /^\d{4}\-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/
    response[:details][:start_at].should =~ date_time_pattern
    response[:details][:end_at].should =~ date_time_pattern
    response[:details][:data].should have(2).items
  end

  it "should should include all sources" do
    policies = [
      FactoryGirl.build(:policy_entries, source: "source 1"),
      FactoryGirl.build(:policy_entries, source: "source 1"),
      FactoryGirl.build(:policy_entries, source: "source 2")
    ]

    response = @presenter.present(policies)

    response[:details][:source].should == ["source 1", "source 2"]
  end

  describe "for each data item" do
    before(:each) do
      @policies = [
        FactoryGirl.build(:policy_entries,
            entries: 123,
            slug: "slug-1",
            policy: FactoryGirl.build(:policy,
              title:      "Title one",
              policy_updated_at: DateTime.new(2012, 12, 12, 12, 12, 12),
              organisations: '{"foo":"bar"}'
            )
        ),
        FactoryGirl.build(:policy_entries,
            entries: 231,
            slug: "slug-2",
            policy: FactoryGirl.build(:policy,
              title: "Title two",
              policy_updated_at: DateTime.new(2012, 12, 13, 12, 12, 12),
              organisations: '{"foo":"bar"}'
            )

        ),
        FactoryGirl.build(:policy_entries,
            entries: 312,
            slug: "slug-2",
            policy: FactoryGirl.build(:policy,
              title:      "Title three",
              policy_updated_at: DateTime.new(2012, 12, 14, 12, 12, 12),
              organisations: '{"foo":"bar"}'
            )
        )
      ]
    end

    it "should have entries for each data item" do
      response = @presenter.present(@policies)

      response[:details][:data].map {|item| item[:entries] }.should == [
        123, 231, 312
      ]
    end

    it "should have a title for each data item" do
      response = @presenter.present(@policies)

      response[:details][:data].map {|item| item[:policy][:title] }.should == [
        "Title one", "Title two", "Title three"
      ]
    end

    it "should have a web url for each data item" do
      response = @presenter.present(@policies)

      response[:details][:data].map {|item| item[:policy][:web_url] }.should == [
        "https://www.gov.uk/government/policies/slug-1",
        "https://www.gov.uk/government/policies/slug-2",
        "https://www.gov.uk/government/policies/slug-2"
      ]
    end

    it "should have an updated_at for each data item" do
      response = @presenter.present(@policies)

      response[:details][:data].map {|item| item[:policy][:updated_at] }.should == [
        DateTime.new(2012, 12, 12, 12, 12, 12),
        DateTime.new(2012, 12, 13, 12, 12, 12),
        DateTime.new(2012, 12, 14, 12, 12, 12)
      ]
    end

    it "should have the organisations for each data item" do
      response = @presenter.present(@policies)

      response[:details][:data].map {|item| item[:policy][:organisations] }.should == [
        {"foo" => "bar"},
        {"foo" => "bar"},
        {"foo" => "bar"},
      ]
    end
  end
end