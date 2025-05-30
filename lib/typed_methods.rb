# frozen_string_literal: true

class Type
  def initialize
    @types = []
  end

  # TODO: make posibility to create type with type variables without typeclass constraints
  def >>(klass)
    @types << klass

    self
  end

  def return_type
    @types.last
  end

  def args_types
    @types[..-2]
  end

  def inspect(...)
    constraints_args = args_types.filter { _1.is_a? TypeClassConstraint }
    constraint_return = return_type if return_type.is_a?(TypeClassConstraint)

    typevariables = ("a".."z").to_a.take(
      constraints_args.size + (constraint_return ? 1 : 0)
    )

    constraints_combined = (constraints_args + [constraint_return]).compact
                                                                   .uniq
                                                                   .zip(typevariables)
                                                                   .to_h

    constraints = if constraints_combined.any?
      "(" + constraints_combined.map { |t, v| t.represent v }
                                .join(", ") + ") => "
                  end

    arg_types = args_types().map do |t|
      case t
      in TypeClassConstraint
        constraints_combined[t]
      in Class
        t.inspect
      end
    end.join(" -> ")

    ":: #{constraints}#{arg_types} -> " \
      "#{constraints_combined[constraint_return] || return_type.inspect}"
  end

  def to_s(...)
    inspect(...)
  end
end

class TypeClassConstraint
  def self.[](...)
    self.make(...)
  end

  def self.make(*typeclasses)
    unless typeclasses.all? { _1.respond_to? :typeclass_methods }
      raise TypeError, "not typeclass passed to #{self.inspect}.#{__method__}"
    end

    new(*typeclasses)
  end


  def represent(typevariable)
    if @typeclasses.size == 1
      ["#{@typeclasses.first.inspect} => #{typevariable}"]
    else
      @typeclasses.map do |t|
        "#{t.inspect} #{typevariable}"
      end
    end
  end

  def inspect(...)
    "(#{represent("a").join(", ")})"
  end

  def satisfy?(klass)
    return false unless klass.respond_to?(:typeclass_instances)

    (@typeclasses - klass.typeclass_instances).empty?
  end

  def >>(klass)
    Type.new >> self >> klass
  end

  private

  def initialize(*typeclasses)
    @typeclasses = typeclasses
  end
end

class Object
  def self.>>(klass)
    Type.new >> self >> klass
  end
end

class Module
  def def_typed(method_name, type, &impl)
    unless type.is_a?(Type)
      raise TypeError, "Incorrect type passed to #{__method__}"
    end

    unless impl
      raise ArgumentError, "No block passed to #{__method__}"
    end

    define_method(method_name) do |*args, **kwargs, &block|
      if (args.size != type.args_types.size)
        raise(ArgumentError,
              "Wrong number of arguments\n" \
              "expected #{type.args_types.size}\n" \
              "got #{args.size}\n" \
              "#{method_name} #{type.inspect}\n")
      end

      args_types_missmatch = args.zip(type.args_types).any? do |a, t|
        case t
        in TypeClassConstraint
          !t.satisfy? a.class
        else
          !a.is_a?(t)
        end
      end

      if args_types_missmatch
        raise(TypeError,
              "Arguments type missmatch\n" \
              "expected #{type.args_types.inspect}\n" \
              "got #{args.map(&:class).inspect}\n" \
              "#{method_name} #{type.inspect}\n")
      end

      result = impl.call(*args, **kwargs, &block)

      result_type_correct = if type.return_type.is_a?(TypeClassConstraint)
                                type.return_type.satisfy? result.class
                              else
                                result.is_a?(type.return_type)
                              end
      unless result_type_correct
        raise(TypeError,
              "Return value type missmatch\n" \
              "expected: #{type.return_type.inspect}\n" \
              "got: #{result.class.inspect}\n" \
              "#{method_name} #{type.inspect}\n")
      end

      result
    end
  end

  def def_typed_curried(method_name, type, &impl)
    unless type.is_a?(Type)
      raise TypeError, "Incorrect type passed to #{__method__}"
    end

    unless impl
      raise ArgumentError, "No block passed to #{__method__}"
    end

    define_method(method_name) do |*args, **kwargs, &block|
      if (args.size > type.args_types.size)
        raise(ArgumentError,
              "Wrong number of arguments\n" \
              "expected 1-#{type.args_types.size}\n" \
              "got #{args.size}\n" \
              "#{method_name} #{type.inspect}\n")
      end
      expected_types = type.args_types.take(args.size)

      args_types_missmatch = args.zip(expected_types).any? do |a, t|
        case t
        in TypeClassConstraint
          !t.satisfy? a.class
        else
          !a.is_a?(t)
        end
      end

      # if (args.zip(expected_types).any? { !_1.is_a?(_2) })
      if args_types_missmatch
        raise(TypeError,
              "Arguments type missmatch\n" \
              "expected #{expected_types.inspect}\n" \
              "got #{args.map(&:class).inspect}\n" \
              "#{method_name} #{type.inspect}\n")
      end

      result = impl.curry.call(*args, **kwargs, &block)

      if result.is_a?(Proc)
        return result
      end

      result_type_correct = if type.return_type.is_a?(TypeClassConstraint)
                                type.return_type.satisfy? result.class
                              else
                                result.is_a?(type.return_type)
                              end

      unless result_type_correct
        raise(TypeError,
              "Return value type missmatch\n" \
              "expected: #{type.return_type.inspect}\n" \
              "got: #{result.class.inspect}\n" \
              "#{method_name} #{type.inspect}\n")
      end

      result
    end
  end
end
