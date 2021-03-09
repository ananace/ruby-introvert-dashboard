# frozen_string_literal: true

require 'concurrent'

module IntrovertDashboard::SSE
  class Connection
    HEARTBEAT_INTERVAL = 30

    attr_accessor :id
    attr_reader :stream

    def initialize(server, stream, id: nil, heartbeat_interval: HEARTBEAT_INTERVAL)
      @server = server
      @stream = stream
      @active = true

      @last_send = Time.now
      @heartbeat_interval = heartbeat_interval
      @id = id || object_id.to_s(16)
      @handlers = []

      @write_lock = Mutex.new
    end

    def logger
      @logger ||= @server.logger
    end

    def alive?
      @active
    end

    def closed(&block)
      @handlers << block
    end

    def heartbeat_interval
      @heartbeat_interval || HEARTBEAT_INTERVAL
    end

    def heartbeat_required?
      (Time.now - @last_send) > heartbeat_interval
    end

    def send_init
      send_event('dashboard.sse', { id: id })
      send_event('dashboard.version', { version: (@version ||= Time.now).to_i.to_s(36) })
    end

    def send_comment(comment = nil)
      @write_lock.lock
      logger.info "Stream|#{id}: Sending comment \"#{comment}\""

      @stream << ": #{comment}\n\n"
      @last_send = Time.now
    ensure
      @write_lock.unlock
    end

    def send_event(event, data, event_id: nil)
      data = data.to_json unless data.is_a? String

      @write_lock.lock
      logger.info "Stream|#{id}: Sending event \"#{event}\" with #{event_id ? "id \"#{event_id}\" and " : nil}#{data.length}B of data"

      @stream << "event: #{event}\n"
      @stream << "id: #{event_id}\n" if event_id
      @stream << "data: #{data.split("\n").join("\ndata: ")}\n\n"
      @last_send = Time.now
    ensure
      @write_lock.unlock
    end

    private

    def closing
      @active = false
      @handlers.each(&:call)
    end
  end
end
