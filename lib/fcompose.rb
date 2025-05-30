# frozen_string_literal: true

class F
  (methods - %i[object_id __send__ __id__]).filter { self.method_defined?(_1) }
                                           .each { self.undef_method(_1) }

  def initialize
    @function ||= F.to_proc
  end

  def self.call(...)
    F.to_proc.call(...)
  end

  def call(...)
    @function.call(...)
  end

  def self.>>(...)
    new.>>(...)
  end

  def self.to_s(...)
    self.method_missing(:to_s)
  end

  def >>(lmb)
    if (lmb in Proc)
      if lmb.arity != 1
        raise(ArgumentError,
              "only lambdas/procs with arity of 1 can be composed " \
              "arity was #{lmb.arity}")
      end
    end

    f = case lmb
        in Symbol | String
          lmb.to_sym.to_proc
        in Proc
          lmb
        end

    @function = @function >> f

    self
  end

  def self.method_missing(method_name, *, **)
    new.method_missing(method_name)
  end

  def method_missing(method_name, *, **)
    @function = @function >> method_name.to_sym.to_proc

    self
  end

  def self.to_proc
    ->(x) { x }
  end

  def to_proc
    @function
  end
end
