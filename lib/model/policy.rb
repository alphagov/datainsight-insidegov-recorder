class Policy
  include DataMapper::Resource

  property :id, Serial
  property :slug, String, required: true
  property :title, String, required: true
  property :department, String, required: true
  property :updated_at, DateTime, required: true

end