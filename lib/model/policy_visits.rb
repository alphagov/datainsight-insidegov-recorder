class PolicyVisits
  include DataMapper::Resource

  property :id, Serial
  property :visits, Integer, required: true
  property :slug, String, required: true

  has 1, :policy,
      :parent_key => [ :slug ],
      :child_key => [ :slug ]

  validates_with_method :visits, method: :is_visits_positive?

  def self.top_5
    PolicyVisits.all(order: [:visits.desc]).take(5)
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