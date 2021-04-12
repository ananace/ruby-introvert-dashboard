# frozen_string_literal: true

module IntrovertDashboard::Workers
  class Manager
    attr_reader :workers

    def initialize
      @workers = []
    end

    def logger
      @logger ||= Logger.new STDOUT
    end

    def register(name, **args, &block)
      logger.info "Registering worker #{name}"

      if name.is_a? Worker
        raise ArgumentError, "Can't pass block with worker instance" unless block.nil?

        @workers << name
      else
        @workers << Worker.new(name, **args, &block)
      end
      @workers.last
    end

    def register_sse(name, stream, **args, &block)
      logger.info "Registering worker #{name} for stream #{stream.id}"
      @workers << SSEWorker.new(name, stream, **args, &block)
      @workers.last
    end

    def get(name, stream: nil)
      @workers.find do |w|
        found = w.name == name
        found &&= w.strea == stream if stream
        found
      end
    end

    def stop(stream)
      worker = @workers.find { |w| w.stream == stream }
      return unless worker

      logger.info "Stopping worker #{worker.name}"

      worker.stop!
      @workers.delete worker
    end

    # TODO Use a thread pool and separate threads, to remove the need for a wrapper and a wait method
    def start_thread
      @thread = Thread.new do
        loop do
          step

          sleep 1
        end
      end
    end

    def step
      @workers.each do |worker|
        begin
          worker.run if worker.status == :running
          worker.wake if worker.status == :sleeping && worker.time_to_wake?
        rescue StandardError => ex
          logger.error "Worker #{worker} failed step with #{ex.class}: #{ex.message}"
        end
      end

      @workers.delete_if { |w| w.status == :stopping }
    end
  end
end
