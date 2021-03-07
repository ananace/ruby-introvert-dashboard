# frozen_string_literal: true

require 'concurrent'

module IntrovertDashboard::SSE
  class Server
    attr_reader :streams

    def initialize
      @streams = []
      @heartbeat = Thread.new { heartbeat_thread }
    end

    def logger
      @logger ||= Logger.new STDOUT
    end

    def handle_connection(stream)
      connection = Connection.new(self, stream)
      logger.info "Adding SSE stream with ID \"#{connection.id}\""

      connection.send_init

      @streams << connection
    end

    def remove_connection(stream)
      connection = @streams.find { |conn| conn.stream == stream }

      logger.info "Closing SSE stream with ID \"#{connection.id}\""
      connection.send :closing

      @streams.delete connection
    end

    def has?(id)
      @streams.any? { |conn| conn.id == id }
    end

    def get(id)
      @streams.find { |conn| conn.id == id }
    end

    def send_event(event, data, to: nil, event_id: nil)
      dest = @streams
      if to
        to = [to] unless to.is_a? Array
        dest = @streams.where { |conn| to.include? conn.id }
      end

      dest.each { |conn| conn.send_event(event, data, event_id: event_id) }
    end

    def send_comment(comment = nil, to: nil)
      dest = @streams
      if to
        to = [to] unless to.is_a? Array
        dest = @streams.where { |conn| to.include? conn.id }
      end

      dest.each { |conn| conn.send_comment(comment) }
    end

    private

    def heartbeat_thread
      loop do
        @streams.each do |conn|
          conn.send_comment("heartbeat") if conn.heartbeat_required?
        end

        sleep 5
      end
    end
  end
end
