require "data_mapper"
require "datainsight_recorder/base_fields"
require "datainsight_recorder/time_series"

require_relative "policy"

class PolicyEntries
  include DataMapper::Resource
  include DataInsight::Recorder::BaseFields
  include DataInsight::Recorder::TimeSeries

  property :entries, Integer, required: true
  property :slug, Text, required: true

  has 1, :policy,
      :parent_key => [:slug],
      :child_key => [:slug]

  validates_with_method :entries, method: :is_entries_positive?

  def self.top_5
    PolicyEntries.all(order: [:entries.desc]).take(5)
  end

  def self.update_from_message(message)
    validate_message(message, :entries)
    return if message[:payload][:value][:entries].nil?
    query = {
      :start_at => DateTime.parse(message[:payload][:start_at]),
      :end_at => DateTime.parse(message[:payload][:end_at]),
      :slug => message[:payload][:value][:slug]
    }
    policy_entries = PolicyEntries.first(query)
    if policy_entries
      logger.info("Update existing record for #{query}")
      policy_entries.entries = message[:payload][:value][:entries]
      policy_entries.slug = message[:payload][:value][:slug]
      policy_entries.source = message[:envelope][:collector]
      policy_entries.collected_at = DateTime.parse(message[:envelope][:collected_at])
      policy_entries.save
    else
      logger.info("Create new record for #{query}")
      PolicyEntries.create(
        :slug => message[:payload][:value][:slug],
        :entries => message[:payload][:value][:entries],
        :start_at => DateTime.parse(message[:payload][:start_at]),
        :end_at => DateTime.parse(message[:payload][:end_at]),
        :collected_at => DateTime.parse(message[:envelope][:collected_at]),
        :source => message[:envelope][:collector]
      )
    end
  end

  def self.validate_message(message, metric)
    raise "No value provided in message payload: #{message.inspect}" unless message[:payload].has_key? :value
    raise "No metric value provided in message payload: #{message.inspect} #{metric}" unless message[:payload][:value].has_key? metric
  end

  def has_metadata?
    not policy.nil?
  end

  private

  def is_entries_positive?
    return [false, "It must be numeric"] unless entries.is_a?(Numeric)
    (@entries >= 0) ? true : [false, "It must be greater than or equal to 0"]
  end

end