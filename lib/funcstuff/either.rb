require_relative "typeclass"
require_relative "square_brackets_initialize"

class Either
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
  extend SquareBracketsInitialize
  include Either.const_get(:Common)

  def inspect(...)
    "Right #{@value.inspect}"
  end
end

class Left < Either
  extend SquareBracketsInitialize
  include Either.const_get(:Common)

  def inspect(...)
    "Left #{@value.inspect}"
  end
end
