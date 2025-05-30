# frozen_string_literal: true

require_relative "monad"

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
    fmap: ->(&block) { self.bind { Maybe.return block.call(_1) } }
  )
end

class Either
  make_typeclass_instance(
    Functor,
    fmap: ->(&block) { self.bind { Either.return block.call(_1) } }
  )
end
