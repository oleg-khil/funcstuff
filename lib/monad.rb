# frozen_string_literal: true

require_relative "typeclass"

module SquareBracketsInitialize
  def [](...)
    new(...)
  end
end

Monad = TypeClass.new(
  bind: nil,
  return: nil,
  # for full monad interface, but i dont think it is really needed cuz its not lazy on argument
  :>> => ->(x) { self.bind { x } }
) do
  def do(&blk)
    raise ArgumentError, "No block provided" unless blk

    dummy_value = Class.new.new
    result = blk.call do |value|
      unless value.class.typeclass_instances.include?(Monad)
        raise(TypeError, "yielded value is not monad")
      end

      ran = false

      unwrapped_value = dummy_value
      value.bind do
        ran = true
        unwrapped_value = _1

        value
      end

      if ran
        next unwrapped_value
      else
        break value
      end
    end

    unless result.class.typeclass_instances.include?(Monad)
      raise(TypeError,
            "Value returned by last expression of do block is not Monad")
    end

    result
  end
end

class Maybe
  make_typeclass_instance(
    Monad,
    bind: ->(&blk) {
      result = case self
      in None
        self
      in Just[x]
        blk.call x
      end

      unless result in Maybe
        raise(TypeError, "Value returned by block passed in bind is not Maybe")
      end

      result
    },
    return: ->(x) { Just[x] }
  ) do
    define_singleton_method(:return, &instance_method(:return).bind(new).to_proc)
    undef_method(:return)
  end
  make_typeclass_instance(
    Eq,
    :== => ->(other) {
      case [self, other]
      in [None, None]
        true
      in [Just[x], Just[y]]
        x == y
      else
        false
      end
    }
  )
end

class Just < Maybe
  singleton_class.undef_method(:return)
  extend SquareBracketsInitialize

  def initialize(value)
    @value = value
  end

  def deconstruct(...)
    [@value]
  end

  def inspect(...)
    "Just #{@value.inspect}"
  end

  def to_s(...)
    inspect(...)
  end
end

class None < Maybe
  singleton_class.undef_method(:return)
  extend SquareBracketsInitialize

  def initialize(...)
  end

  def deconstruct(...)
    []
  end

  def inspect(...)
    "None"
  end

  def to_s(...)
    inspect(...)
  end
end

class Either
  make_typeclass_instance(
    Monad,
    bind: ->(&blk) {
      result = case self
      in Left
        self
      in Right[x]
        blk.call x
      end

      unless result in Either
        raise(TypeError, "Value returned by block passed in bind is not Either")
      end

      result
    },
    return: ->(x) { Right[x] }
  ) do
    define_singleton_method(:return, &instance_method(:return).bind(new).to_proc)
    undef_method(:return)
  end

  make_typeclass_instance(
    Eq,
    :== => ->(other) {
      case [self, other]
      in [Left[x], Left[y]]
        x == y
      in [Right[x], Right[y]]
        x == y
      else
        false
      end
    }
  )

  def self.capture(&block)
    Right[yield]
  rescue StandardError => e
    Left[e]
  end

  module Common
    def initialize(value)
      @value = value
    end

    def deconstruct(...)
      [@value]
    end

    def to_s(...)
      inspect(...)
    end
  end
  private_constant :Common
end

class Right < Either
  singleton_class.undef_method(:return)
  extend SquareBracketsInitialize
  include Either.const_get(:Common)

  def inspect(...)
    "Right #{@value.inspect}"
  end
end

class Left < Either
  singleton_class.undef_method(:return)
  extend SquareBracketsInitialize
  include Either.const_get(:Common)

  def inspect(...)
    "Left #{@value.inspect}"
  end
end

module Enumerable
  def first_maybe
    Just[to_enum.next]
  rescue StopIteration
    None[]
  end

  def find_maybe(fn = nil, &block)
    if !block && !fn
      raise ArgumentError, "No block/proc given"
    end

    to_enum.lazy.filter do |e|
      block ? yield(e) : fn.call(e)
    end.first_maybe
  end
end

class Array
  def fetch_maybe(...)
    Just[self.fetch(...)]
  rescue IndexError
    None[]
  end
end

class Hash
  def fetch_maybe(...)
    Just[self.fetch(...)]
  rescue KeyError
    None[]
  end
end

ENV.define_singleton_method(:fetch_maybe) do |*args, **kwargs, &block|
  Just[self.fetch(*args, **kwargs, &block)]
rescue KeyError
  None[]
end
