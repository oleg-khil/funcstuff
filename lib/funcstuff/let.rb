# frozen_string_literal: true

class Let
  def self.call(...)
    self.new(...)
  end

  def call(name, &blk)
    @binds[name.to_s.to_sym] = blk

    self
  end

  def in(&blk)
    @caller = blk.__send__(:binding).receiver

    @binds.each do |k, v|
      define_singleton_method(k.to_sym) do |*args, **kwargs, &block|
        cache = instance_variable_get("@#{k.to_sym}")
        return cache if cache
        result = instance_exec(&v)

        if result.is_a?(Proc)
          define_singleton_method(k.to_sym, &result)
          __send__(k.to_sym, *args, **kwargs, &block)
        else
          instance_variable_set("@#{k.to_sym}", result)
        end
      end
    end

    result = instance_exec(&blk)

    @binds.keys.each do |k|
      instance_variable_set("@#{k.to_sym}", nil)
    end

    result
  end

  def method_missing(method_name, *args, **kwargs, &block)
    if @caller&.__send__(:respond_to?, method_name)
      @caller.__send__(method_name, *args, **kwargs, &block)
    else
      super
    end
  end

  private

  def initialize(...)
    @binds = {}
    self.call(...)
  end
end
