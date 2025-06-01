# frozen_string_literal: true

require_relative "maybe"
require_relative "either"

Functor = TypeClass.new(
  fmap: nil
)

class Array
  make_typeclass_instance(
    Functor,
    fmap: ->(&block) { self.map(&block) }
  )
end

class Maybe
  make_typeclass_instance(
    Functor,
    fmap: ->(&block) {
      case self
      in Just[x]
        Just[block.call(x)]
      in None
        self
      end
    }
  )
end

class Either
  make_typeclass_instance(
    Functor,
    fmap: ->(&block) {
      case self
      in Right[x]
        Right[block.call(x)]
      in Left
        self
      end
    }
  )
end
