class Policy
  include DataMapper::Resource
  include DataInsight::Recorder::BaseFields

  property :slug, String, required: true
  property :title, String, required: true
  property :department, String, required: true
end