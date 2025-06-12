require_relative "typeclass"
require_relative "square_brackets_initialize"

class Maybe
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
  def to_either
    case self
    in Just[x]
      Right[x]
    in None
      Left[None]
    end
  end
end

class Just < Maybe
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
