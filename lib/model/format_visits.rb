require "datainsight_recorder/base_fields"

class FormatVisits
  include DataMapper::Resource
  include DataInsight::Recorder::BaseFields
  include DataInsight::Recorder::TimeSeries

  property :format, String, required: true
  property :entries, Integer, required: true
  property :successes, Integer, required: true


  def self.last_week_visits
    self.all(start_at: max(:start_at))
  end


  def self.update_from_message(message)
    validate(message)

    attributes = {
        format: message[:payload][:value][:format],
        entries: message[:payload][:value][:entries],
        successes: message[:payload][:value][:successes],
        start_at: DateTime.parse(message[:payload][:start_at]),
        end_at: DateTime.parse(message[:payload][:end_at]),
        collected_at: DateTime.parse(message[:envelope][:collected_at]),
        source: message[:envelope][:collector]
    }

    query = {
        start_at: attributes[:start_at],
        end_at: attributes[:end_at],
        format: attributes[:format]
    }

    fv = FormatVisits.first_or_new(query)
    fv.attributes = attributes
    fv.save
  end

  private
  def self.validate(message)
    check_date(message, :envelope, :collected_at)
    check_present(message, :envelope, :collector)
    check_date(message, :payload, :start_at)
    check_date(message, :payload, :end_at)
    check_present(message, :payload, :value, :format)
    check_integer(message, :payload, :value, :entries)
    check_integer(message, :payload, :value, :successes)
  end

  def self.check_date(message, *properties)
    check(message, *properties) { |value| value.present? && valid_date?(value) }
  end

  def self.check_integer(message, *properties)
    check(message, *properties) { |value| value.is_a? Integer }
  end

  def self.check_present(message, *properties)
    check(message, *properties) { |property| property.present? }
  end

  def self.check(message, *properties)
    property_name = properties.map(&:to_s).join('.')
    property_value = get_property(message, properties)
    raise InvalidMessageError.new("property '#{property_name}' is missing or invalid; message: #{message}" ) unless yield property_value
  end

  def self.get_property(message, properties)
    current_value = message
    properties.each do |p|
      current_value = current_value.is_a?(Hash) ? current_value[p] : nil
    end
    current_value
  end

  def self.valid_date?(value)
    DateTime.parse(value)
    true
  rescue
    false
  end

end
