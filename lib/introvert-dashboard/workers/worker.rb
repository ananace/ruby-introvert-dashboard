# frozen_string_literal: true

require 'fiber'

$fr = Fiber.current

module IntrovertDashboard::Workers
  class Worker
    attr_reader :fiber, :name, :binding, :params, :status, :wake_at

    def initialize(name, binding: nil, params: nil, &block)
      @name = name
      @block = block
      @binding = binding
      @params = params || {}
      @status = :running
    end

    def run
      @fiber ||= Fiber.new do
        stack = IntrovertDashboard::LookupStack.new
        stack.push_binding(binding)
        stack.push_binding(@binding) if @binding
        stack.push_hash(@params) if @params.any?
        stack.push_instance(Wrapper.new(self))

        if @block.arity == -1
          stack.run_proc(@block, self)
        else
          stack.run_proc(@block)
        end
      end
      @fiber.resume
      true
    rescue FiberError
      false
    end

    def running?
      @status == :running
    end

    def time_to_wake?
      @status == :sleeping && !@wake_at.nil? && Time.now >= @wake_at
    end

    def stop!
      @status = :stopping
    end

    def wait(duration = nil)
      return wait!(to: Time.now + duration) if Fiber.current == $fr

      start = Time.now
      if duration
        wait!(to: start + duration)
      else
        wait!
      end
      self.yield
      Time.now - start
    end

    def yield
      return if Fiber.current == $fc

      Fiber.yield
    end

    def wait!(to: nil)
      @status = :sleeping
      @wake_at = to if to
    end

    def wake
      @fiber&.resume
    end

    class Wrapper
      attr_reader :worker

      def initialize(worker)
        @worker = worker
      end

      def wait(duration = nil)
        if duration
          worker.wait(duration)
        else
          worker.wait
        end
      end
    end
  end

  class SSEWorker < Worker
    attr_reader :stream

    def initialize(name, stream, **args, &block)
      @stream = stream
      @stream.closed { stop! }

      super("#{name}|#{stream.id}", **args, &block)
    end

    def run
      return stop! unless @stream.alive?

      super
    end
  end
end
