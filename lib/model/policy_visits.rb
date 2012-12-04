class PolicyVisits
  include DataMapper::Resource

  property :id, Serial
  property :visits, Integer, required: true
  property :slug, String, required: true

  has 1, :policy,
      :parent_key => [ :slug ],
      :child_key => [ :slug ]

  def self.top_5
    PolicyVisits.all(order: [:visits.desc]).take(5)
  end

end