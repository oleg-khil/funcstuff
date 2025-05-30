# frozen_string_literal: true

module Curry
  def curry_self(method_name)
    define_singleton_method(method_name, &method(method_name).to_proc.curry)
  end

  def curry_instance(method_name)
    unbound_method = instance_method(method_name)
    define_method(method_name) do |*args, **kwargs, &block|
      unbound_method.bind(self).curry.call(*args, **kwargs, &block)
    end
  end
end
