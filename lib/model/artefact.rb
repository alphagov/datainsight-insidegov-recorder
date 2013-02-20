require "data_mapper"
require "datainsight_recorder/base_fields"

class Artefact
  include DataMapper::Resource
  include DataInsight::Recorder::BaseFields

  property :format, String, required: true
  property :slug, String, length: 255, required: true
  property :title, Text, required: true
  property :url, Text, required: true
  property :organisations, Text, required: true
  property :artefact_updated_at, DateTime, required: true
  property :disabled, Boolean, required: true, default: false

  def self.update_from_message(message)
    payload = message[:payload]

    slug = payload[:url]
      .downcase
      .gsub(Regexp.new("^/government/[^/]+/"), "")
    format = transform_type(payload[:type])

    query = {
      :slug => slug,
      :format => format
    }
    artefact = Artefact.first(query)
    unless artefact
      artefact = Artefact.new(
        slug: slug,
        format: format
      )
    end
    artefact.title = payload[:title]
    artefact.url = payload[:url]
    raise if payload[:organisations].nil?
    artefact.organisations = payload[:organisations].to_json
    artefact.artefact_updated_at = DateTime.parse(payload[:updated_at])
    artefact.collected_at = DateTime.parse(message[:envelope][:collected_at])
    artefact.source = message[:envelope][:collector]
    artefact.disabled = false

    artefact.valid?
    artefact.errors.each do |error|
      puts error
    end
    artefact.save
  end

  private
  def self.transform_type(type)
    case type
    when "news_article"
      "news"
    else
      type
    end
  end

end