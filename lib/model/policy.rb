require "data_mapper"
require "datainsight_recorder/base_fields"

class Policy
  include DataMapper::Resource
  include DataInsight::Recorder::BaseFields

  property :slug, Text, required: true
  property :title, Text, required: true
  property :organisations, Text, required: true
  property :policy_updated_at, DateTime, required: false
  property :disabled, Boolean, required: true, default: false

  def self.update_from_message(message)
    message[:payload][:url] = message[:payload][:url]
      .downcase
      .gsub(/^\/government\/policies\//, "")

    query = {
      :slug => message[:payload][:url]
    }
    policy = Policy.first(query)
    unless policy
      policy = Policy.new(slug: message[:payload][:url])
    end
    policy.title = message[:payload][:title]
    raise if message[:payload][:organisations].nil?
    policy.organisations = message[:payload][:organisations].to_json
    policy.policy_updated_at = message[:payload][:updated_at].nil? ? nil : DateTime.parse(message[:payload][:updated_at])
    policy.collected_at = DateTime.parse(message[:envelope][:collected_at])
    policy.source = message[:envelope][:collector]
    policy.disabled = false
    policy.save
  end
end