require "json"

require "bundler/setup"
Bundler.require(:default, :recorder)

require_relative "model/weekly_reach"

class Recorder
  ROUTING_KEYS = ["google_analytics.inside_gov.visitors.weekly"]

  def run
    queue.subscribe do |msg|
      begin
        logger.debug { "Received a message: #{msg}" }
        process_message(parse_amqp_message(msg))
      rescue Exception => e
        logger.error { e }
      end
    end
  end

  def process_message(message)
    metric = :visitors
    validate_message(message, metric)
    params = {
        :metric => metric,
        :start_at => parse_start_at(message[:payload][:start_at]),
        :end_at => parse_end_at(message[:payload][:end_at])
    }
    weekly_visitors = WeeklyReach.first(params)
    if message[:payload][:value][metric].nil?
      if weekly_visitors
        weekly_visitors.destroy
      end
    else
      if weekly_visitors
        logger.info("SAVE EXISTING")
        weekly_visitors.value = message[:payload][:value][metric]
        weekly_visitors.source = message[:envelope][:collector] # to get around migration
        weekly_visitors.collected_at = message[:envelope][:collected_at]
        weekly_visitors.save
      else
        logger.info("CREATE NEW")
        WeeklyReach.create(
            :value => message[:payload][:value][metric],
            :metric => metric,
            :start_at => parse_start_at(message[:payload][:start_at]),
            :end_at => parse_end_at(message[:payload][:end_at]),
            :collected_at => DateTime.parse(message[:envelope][:collected_at]),
            :source => message[:envelope][:collector]
        )
      end
    end
  end

  private
  def validate_message(message, metric)
    raise "No value provided in message payload: #{message.inspect}" unless message[:payload].has_key? :value
    raise "No metric value provided in message payload: #{message.inspect} #{metric}" unless message[:payload][:value].has_key? metric
    unless message[:payload][:value][metric].nil? or message[:payload][:value][metric].is_a? Integer
      raise "Invalid value provided in message payload: #{message.inspect}"
    end
  end

  def queue
    @queue ||= create_queue
  end

  def create_queue
    client = Bunny.new ENV["AMQP"]
    client.start
    queue = client.queue(ENV["QUEUE"] || "insidegov")
    exchange = client.exchange("datainsight", :type => :topic)

    ROUTING_KEYS.each do |key|
      queue.bind(exchange, :key => key)
      logger.info("Bound to #{key}, listening for events")
    end

    queue
  end

  def parse_amqp_message(raw_message)
    message = JSON.parse(raw_message[:payload], :symbolize_names => true)
    message[:envelope][:_routing_key] = raw_message[:delivery_details][:routing_key]
    message
  end

  def parse_start_at(start_at)
    DateTime.parse(start_at)
  end

  # This recorder stores start and end as dates while the message format uses date times on date boundaries (midnight).
  # This means that the date may have to be shifted back
  def parse_end_at(end_at)
    end_at = DateTime.parse(end_at)
    if (end_at.hour + end_at.minute + end_at.second) == 0
      # up to midnight, so including the previous day
      end_at - 1
    else
      end_at
    end
  end

end
