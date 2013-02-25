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

  describe "top last available week" do
    before(:each) do
      15.times do |n|
        params = {
          entries: (n+2) * 1000,
          start_at: DateTime.new(2012, 12, 16),
          end_at: DateTime.new(2012, 12, 23)
        }
        FactoryGirl.create :policy_entries, params
      end
      15.times do |n|
        params = {
          entries: (n+1) * 1000,
          start_at: DateTime.new(2012, 12, 23),
          end_at: DateTime.new(2012, 12, 30)
        }
        FactoryGirl.create :policy_entries, params
      end
    end

    it "should not return policy entries if there is no corresponding policy" do
      Artefact.all.destroy
      Timecop.travel(DateTime.new(2012, 12, 31, 13, 32)) do
        top_five = PolicyEntries.top_last_week(5)
        top_five.should have(0).items
      end
    end

    it "should not return policy entries if the corresponding policy is disabled" do
      entry = PolicyEntries.top_last_week(5).first
      entry.policy.update(disabled: true)
      Timecop.travel(DateTime.new(2012, 12, 31, 13, 32)) do
        top_five = PolicyEntries.top_last_week(5)
        top_five.should_not include entry
      end
    end

    it "should return the top 5 elements for last week" do
      Timecop.travel(DateTime.new(2012, 12, 31, 13, 32)) do
        top_five = PolicyEntries.top_last_week(5)

        top_five.should have(5).items
        top_five.first.entries.should == 15000
        top_five.first.start_at.should == DateTime.new(2012, 12, 23)
        top_five.first.end_at.should == DateTime.new(2012, 12, 30)

        top_five.last.entries.should == 11000
        top_five.last.start_at.should == DateTime.new(2012, 12, 23)
        top_five.last.end_at.should == DateTime.new(2012, 12, 30)
      end
    end

    it "should return the top 10 elements for last week" do
      Timecop.travel(DateTime.new(2012, 12, 31, 13, 32)) do
        top_ten = PolicyEntries.top_last_week(10)

        top_ten.should have(10).items

        top_ten.first.entries.should == 15000
        top_ten.first.start_at.should == DateTime.new(2012, 12, 23)
        top_ten.first.end_at.should == DateTime.new(2012, 12, 30)

        top_ten.last.entries.should == 6000
        top_ten.last.start_at.should == DateTime.new(2012, 12, 23)
        top_ten.last.end_at.should == DateTime.new(2012, 12, 30)
      end
    end

    it "should return the top 5 elements for the last available week" do
      Timecop.travel(DateTime.new(2013, 1, 10, 12, 12)) do
        top_five = PolicyEntries.top_last_week(5)

        top_five.should have(5).items
        top_five.first.entries.should == 15000
        top_five.first.start_at.should == DateTime.new(2012, 12, 23)
        top_five.first.end_at.should == DateTime.new(2012, 12, 30)

        top_five.last.entries.should == 11000
        top_five.last.start_at.should == DateTime.new(2012, 12, 23)
        top_five.last.end_at.should == DateTime.new(2012, 12, 30)
      end
    end
  end

  describe "policy join" do
    before(:each) do
      FactoryGirl.create :policy_entries, slug: "/my-slug"
    end

    it "should return the joined policy" do
      policy_entries = PolicyEntries.first
      policy_entries.policy.should be_an(Artefact)
      policy_entries.policy.slug.should == "/my-slug"
    end

    it "should return nil if no policy is" do
      Artefact.destroy
      policy_entries = PolicyEntries.first
      policy_entries.policy.should be_nil
    end

  end

  describe "update from message" do
    before(:each) do
      @message = {
        :envelope => {
          :collected_at => DateTime.now.strftime,
          :collector    => "Google Analytics",
          :_routing_key => "google_analytics.insidegov.policy_entries.weekly"
        },
        :payload => {
          :start_at => "2011-03-28T00:00:00",
          :end_at => "2011-04-04T00:00:00",
          :value => {
            :entries => 700,
            :slug => "/government/policies/some-policy"
          }
        }
      }
    end

    it "should save a new policy_entries record" do
      PolicyEntries.update_from_message(@message)

      PolicyEntries.count.should == 1
      item = PolicyEntries.first
      item.entries.should == 700
      item.start_at.should == DateTime.new(2011, 3, 28)
      item.end_at.should == DateTime.new(2011, 4, 4)
    end

    it "should update an existing policy_entries record" do
      record = PolicyEntries.new(
        collected_at: DateTime.now,
        source: "Google Analytics",
        start_at: DateTime.new(2011, 3, 28),
        end_at: DateTime.new(2011, 4, 4),
        entries: 700,
        slug: "/government/policies/some-policy"
      )
      record.save

      @message[:payload][:value][:entries] = 800
      PolicyEntries.update_from_message(@message)

      PolicyEntries.count.should == 1
      item = PolicyEntries.first
      item.entries.should == 800
      item.start_at.should == DateTime.new(2011, 3, 28)
      item.end_at.should == DateTime.new(2011, 4, 4)
    end

    it "should lowercase slugs" do
      @message[:payload][:value][:slug] = "/GOVERNMENT/POLICIES/SOME-POLICY"

      PolicyEntries.update_from_message(@message)

      PolicyEntries.first.slug.should == "/government/policies/some-policy"
    end

    it "should update slugs" do
      record = PolicyEntries.new(
        collected_at: DateTime.now,
        source: "Google Analytics",
        start_at: DateTime.new(2011, 3, 28),
        end_at: DateTime.new(2011, 4, 4),
        entries: 700,
        slug: "/GOVERNMENT/POLICIES/SOME-POLICY"
      )
      record.save

      PolicyEntries.update_from_message(@message)

      PolicyEntries.first.slug.should == "/government/policies/some-policy"
    end
  end
end