# frozen_string_literal: true

module IntrovertDashboard
  class LookupStack
    def initialize(bindings = [])
      @bindings = bindings
    end

    def method_missing(m, *args)
      @bindings.reverse_each do |bind|
        begin
          method = eval(format('method(%s)', m.inspect), bind)
        rescue NameError
        else
          return method.call(*args)
        end

        begin
          value = eval(m.to_s, bind)
          return value
        rescue NameError
        end
      end
      raise NoMethodError
    end

    def push_binding(bind)
      @bindings.push bind
    end

    def push_instance(obj)
      @bindings.push(obj.instance_eval { binding })
    end

    def push_hash(vars)
      push_instance Struct.new(*vars.keys).new(*vars.values)
    end

    def run_proc(p, *args)
      instance_exec(*args, &p)
    end
  end
end
