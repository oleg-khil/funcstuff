# frozen_string_literal: true

class Class
  def derive_typeclass(type_class)
    unless type_class.typeclass_derivable
      raise ArgumentError, "typeclass #{type_class.inspect} is not derivable"
    end

    make_typeclass_instance(type_class)
  end

  def make_typeclass_instance(type_class, **methods, &block)
    unless (type_class.typeclass_methods_wo_impl - methods.keys).empty?
      raise NotImplementedError,
            "not all required typeclass methods is implemented " \
            "required: [#{type_class.typeclass_methods_wo_impl.join(", ")}]; " \
            "implemented: [#{methods.keys.join(", ")}]"
    end

    unless (methods.keys - type_class.typeclass_methods).empty?
      raise NotImplementedError,
            "implementation of methods not required by typeclass was provided " \
            "required: [#{type_class.typeclass_methods_wo_impl.join(", ")}]; " \
            "all typeclass methods: [#{type_class.typeclass_methods.join(", ")}]; " \
            "implemented: [#{methods.keys.join(", ")}]"
    end

    symbol_procs = methods.filter do |name, impl|
      begin
        impl.binding && false
      rescue ArgumentError
        true
      end
    end.keys

    if symbol_procs.any?
      # TODO: maybe there is solution to this by currying lambda and binding first argument to self in runtime
      raise(NotImplementedError,
            "implementation of [#{symbol_procs.join(", ")}] is probably without " \
            "receiver and was made by calling to_proc on symbol, this " \
            "type of procs (C level Proc) is unsupported")
    end

    (type_class.typeclass_methods - type_class.typeclass_methods_wo_impl).each do |m|
      define_method(m, &type_class.typeclass_methods_w_impl[m].to_proc)
    end

    methods.each do |name, impl|
      define_method(name, &impl)
    end

    instances = (
      [type_class] +
        (self.respond_to?(:typeclass_instances) ? self.typeclass_instances : [])
    ).sort_by(&:name).freeze


    define_singleton_method(:typeclass_instances) { instances }

    instance_exec(&block) if block
  end
end

module TypeClass
  def self.new(**methods, &blk)
    mod = Module.new do
      w_imp = methods.filter { |_, impl| impl in Proc }
      wo_imp = methods.keys - w_imp.keys
      all = w_imp.keys + wo_imp
      derivable = wo_imp.empty?

      define_singleton_method(:typeclass_methods) { all }
      define_singleton_method(:typeclass_methods_w_impl) { w_imp }
      define_singleton_method(:typeclass_methods_wo_impl) { wo_imp }
      define_singleton_method(:typeclass_derivable) { derivable }
    end
    mod.instance_exec(&blk) if blk

    mod
  end
end

ToNix = TypeClass.new(
  to_nix: nil
)

Show = TypeClass.new(
  show: -> { self.to_s }
)

Eq = TypeClass.new(
  :== => ->(other) { other.object_id == self.object_id }
)

class Integer
  derive_typeclass(Show)
end

class Numeric
  make_typeclass_instance(
    ToNix,
    to_nix: -> { self.to_s }
  )
end

class Rational
  make_typeclass_instance(
    ToNix,
    to_nix: -> { self.to_f.to_s }
  )
end

class String
  make_typeclass_instance(
    ToNix,
    to_nix: -> { self.inspect }
  )
end

class Pathname
  make_typeclass_instance(
    ToNix,
    to_nix: -> { self.to_s }
  )
end

class TrueClass
  make_typeclass_instance(
    ToNix,
    to_nix: -> { self.to_s }
  )
end

class FalseClass
  make_typeclass_instance(
    ToNix,
    to_nix: -> { self.to_s }
  )
end

class Hash
  make_typeclass_instance(
    ToNix,
    to_nix: -> {
      "{ " +
        self.map { |k, v| "#{k.to_s.inspect} = #{v.to_nix};" }.join(" ") +
          " }"
    }
  )
end

class Proc
  make_typeclass_instance(
    ToNix,
    to_nix: -> { self.call }
  )
end

class Array
  make_typeclass_instance(
    ToNix,
    to_nix: -> {
      "[ " + self.map(&:to_nix).join(" ") + " ]"
    }
  )
end
