require "data_mapper"
require "datainsight_recorder/base_fields"

class Policy
  include DataMapper::Resource
  include DataInsight::Recorder::BaseFields

  property :slug, Text, required: true
  property :title, Text, required: true
  property :department, String, required: true
end