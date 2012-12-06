class PolicyVisits
  include DataMapper::Resource
  include DataInsight::Recorder::BaseFields
  include DataInsight::Recorder::TimeSeries

  property :visits, Integer, required: true
  property :slug, String, required: true

  has 1, :policy,
      :parent_key => [:slug],
      :child_key => [:slug]

  validates_with_method :visits, method: :is_visits_positive?

  def self.top_5
    PolicyVisits.all(order: [:visits.desc]).take(5)
  end

  def self.update_from_message(message)
    validate_message(message, :visits)
    return if message[:payload][:value][:visits].nil?
    query = {
      :start_at => DateTime.parse(message[:payload][:start_at]),
      :end_at => DateTime.parse(message[:payload][:end_at])
    }
    policy_visits = PolicyVisits.first(query)
    if policy_visits
      logger.info("Update existing record for #{query}")
      policy_visits.visits = message[:payload][:value][:visits]
      policy_visits.slug = message[:payload][:value][:slug]
      policy_visits.source = message[:envelope][:collector]
      policy_visits.collected_at = message[:envelope][:collected_at]
      policy_visits.save
    else
      logger.info("Create new record for #{query}")
      PolicyVisits.create(
        :slug => message[:payload][:value][:slug],
        :visits => message[:payload][:value][:visits],
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

  def is_visits_positive?
    return [false, "It must be numeric"] unless @visits.is_a?(Numeric)
    (@visits >= 0) ? true : [false, "It must be greater than or equal to 0"]
  end

end