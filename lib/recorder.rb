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
        WeeklyReach.update_from_message(parse_amqp_message(msg))
      rescue Exception => e
        logger.error { e }
      end
    end
  end

  private
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
end
