# frozen_string_literal: true

require_relative "functor"

Applicative = TypeClass.new(
  pure: nil,
  ap: nil
)

class Array
  make_typeclass_instance(
    Applicative,
    pure: ->(x) { [x] },
    ap: ->(vs) {
      self.flat_map do |f|
        vs.map(&f)
      end
    }
  ) do
    define_singleton_method(:pure, &instance_method(:pure).bind(new).to_proc)
    undef_method(:pure)
  end
end

class Maybe
  make_typeclass_instance(
    Applicative,
    pure: ->(x) { Just[x] },
    ap: ->(v) {
      case self
      in Just[f]
        v.fmap(&f)
      in None
        self
      end
    }
  ) do
    define_singleton_method(:pure, &instance_method(:pure).bind(new).to_proc)
    undef_method(:pure)
  end
end

class Either
  make_typeclass_instance(
    Applicative,
    pure: ->(x) { Either.return x },
    ap: ->(v) {
      case self
      in Right[f]
        v.fmap(&f)
      in Left
        self
      end
    }
  ) do
    define_singleton_method(:pure, &instance_method(:pure).bind(new).to_proc)
    undef_method(:pure)
  end
end
