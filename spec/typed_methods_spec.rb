# frozen_string_literal: true

class ClassForTest
  def_typed(:typed, Integer >> Numeric >> Numeric) do |a, b|
    a + b
  end

  def_typed(:typeclass_constrained, TypeClassConstraint[Show] >> String >> String) do
    |a, prefix|
    prefix + a.show
  end

  def_typed(:typeclass_constrained_return_type, Numeric >> TypeClassConstraint[Monad]) do
    |a|

    if a % 2 == 0
      a
    else
      Either.return a
    end
  end

  def_typed_curried(:curried, Integer >> Numeric >> Numeric) do |a, b|
    a + b
  end

  def_typed(:multiple_typeclass_constrained, TypeClassConstraint[Monad, Functor] >> Maybe) do |a|
    a.fmap(&:inspect).bind { Maybe.return _1.upcase }
  end

  def_typed(:wrong_return_type, Numeric >> Numeric >> String) do |a, b|
    a + b
  end

  class << self
    def_typed(:typed, Integer >> Numeric >> Numeric) do |a, b|
      a + b
    end
  end
end

describe "typed_methods" do
  let(:klass) { ClassForTest }
  let(:instance) { klass.new }
  let(:fn) { instance.method(method_name) }

  describe "def_typed" do
    describe "regular typed method" do
      let(:method_name) { :typed }

      it "must succeed if types are correct" do
        _(fn.call 1, 2.0).must_equal 1 + 2.0
      end

      it "must raise if types are incorrect" do
        _ { fn.call 1, 2.0.to_s }.must_raise TypeError
      end

      it "must raise if arguments count is wrong" do
        _ { fn.call 1 }.must_raise ArgumentError
        _ { fn.call 1, 2.0.to_s, 3 }.must_raise ArgumentError
      end

      describe "when return type is wrong" do
        let(:method_name) { :wrong_return_type }

        it "must raise" do
          _ { fn.call 1, 2 }.must_raise TypeError
        end
      end

      describe "defined as class method" do
        it "must succeed if types are correct" do
          _(klass.__send__(method_name, 1, 2.0)).must_equal 1 + 2.0
        end

        it "must raise if types are incorrect" do
          _ { klass.__send__(method_name, 1, 2.0.to_s) }.must_raise TypeError
        end

        it "must raise if arguments count is wrong" do
          _ { klass.__send__(method_name, 1) }.must_raise ArgumentError
          _ { klass.__send__(method_name, 1, 2.0.to_s, 3) }.must_raise ArgumentError
        end
      end
    end

    describe "typeclass constrained method" do
      let(:method_name) { :typeclass_constrained }

      it "must succeed if types are correct and satisfy typeclass constraint" do
        _(fn.call 1, 2.to_s).must_equal 2.to_s + 1.show
      end

      it "must raise if types are incorrect" do
        _ { fn.call 1, 2.0 }.must_raise TypeError
      end

      it "must raise if typeclass constraint is not satisfied" do
        _ { fn.call 1.0, 2.0 }.must_raise TypeError
      end
    end

    describe "typeclass_constrained method" do
      let(:method_name) { :typeclass_constrained }

      it "must succeed if types are correct and satisfy typeclass constraint" do
        _(fn.call 1, 2.to_s).must_equal 2.to_s + 1.show
      end

      it "must raise if types are incorrect" do
        _ { fn.call 1, 2.0 }.must_raise TypeError
      end

      it "must raise if typeclass constraint is not satisfied" do
        _ { fn.call 1.0, 2.0 }.must_raise TypeError
      end
    end

    describe "method with multiple typeclass constraints" do
      let(:method_name) { :multiple_typeclass_constrained }

      it "must succeed if all typeclass constraints are satisfied" do
        _(fn.call Just["a"]).must_equal Maybe.return('"A"')
      end

      it "must raise if not all typeclass constraints are satisfied" do
        _ { fn.call ["a"] }.must_raise TypeError
      end
    end

    describe "method with typeclass constrainted return type" do
      let(:method_name) { :typeclass_constrained_return_type }

      it "must succeed if return typeclass constraint is satisfied" do
        _(fn.call 1).must_equal Either.return(1)
      end

      it "must raise if return typeclass constraint is not satisfied" do
        _ { fn.call 2 }.must_raise TypeError
      end
    end
  end

  describe "def_typed_curried" do
    describe "when all args passed it must act like uncurried" do
      let(:method_name) { :curried }

      it "must succeed if types are correct" do
        _(fn.call 1, 2.0).must_equal 1 + 2.0
      end

      it "must raise if types are incorrect" do
        _ { fn.call 1, 2.0.to_s }.must_raise TypeError
      end
    end

    describe "when not all args passed it must check passed args and return proc" do
      let(:method_name) { :curried }

      it "must succeed if types are correct" do
        _(fn.call 1).must_be_instance_of Proc
      end

      it "must raise if types are incorrect" do
        _ { fn.call 2.0 }.must_raise TypeError
      end

      it "must raise if arguments count is more than it should" do
        _ { fn.call 1, 2.0.to_s, 3 }.must_raise ArgumentError
      end
    end
  end

  describe "typed lambdas" do
    let(:fn) { __send__(method_name) }

    let(:typed) {
      (Integer >> Numeric >> Numeric).lambda(:typed) do |a, b|
        a + b
      end
    }
    let(:typeclass_constrained) {
      (TypeClassConstraint[Show] >> String >> String).lambda(:typeclass_constrained) do
        |a, prefix|
        prefix + a.show
      end
    }
    let(:typeclass_constrained_return_type) {
      (Numeric >> TypeClassConstraint[Monad]).lambda(:typeclass_constrained_return_type) do
        |a|

        if a % 2 == 0
          a
        else
          Either.return a
        end
      end
    }
    let(:curried) {
      (Integer >> Numeric >> Numeric).lambda_curried(:curried) do |a, b|
        a + b
      end
    }
    let(:multiple_typeclass_constrained) {
      (TypeClassConstraint[Monad, Functor] >> Maybe).lambda(:multiple_typeclass_constrained) do |a|
        a.fmap(&:inspect).bind { Maybe.return _1.upcase }
      end
    }

    let(:wrong_return_type) {
      (Numeric >> Numeric >> String).lambda(:wrong_return_type) do |a, b|
        a + b
      end
    }

    describe "regular" do
      let(:method_name) { :typed }

      it "must succeed if types are correct" do
        _(fn.call 1, 2.0).must_equal 1 + 2.0
      end

      it "must raise if types are incorrect" do
        _ { fn.call 1, 2.0.to_s }.must_raise TypeError
      end

      it "must raise if arguments count is wrong" do
        _ { fn.call 1 }.must_raise ArgumentError
        _ { fn.call 1, 2.0.to_s, 3 }.must_raise ArgumentError
      end

      describe "when return type is wrong" do
        let(:method_name) { :wrong_return_type }

        it "must raise" do
          _ { fn.call 1, 2 }.must_raise TypeError
        end
      end
    end

    describe "typeclass constrained method" do
      let(:method_name) { :typeclass_constrained }

      it "must succeed if types are correct and satisfy typeclass constraint" do
        _(fn.call 1, 2.to_s).must_equal 2.to_s + 1.show
      end

      it "must raise if types are incorrect" do
        _ { fn.call 1, 2.0 }.must_raise TypeError
      end

      it "must raise if typeclass constraint is not satisfied" do
        _ { fn.call 1.0, 2.0 }.must_raise TypeError
      end
    end

    describe "typeclass_constrained method" do
      let(:method_name) { :typeclass_constrained }

      it "must succeed if types are correct and satisfy typeclass constraint" do
        _(fn.call 1, 2.to_s).must_equal 2.to_s + 1.show
      end

      it "must raise if types are incorrect" do
        _ { fn.call 1, 2.0 }.must_raise TypeError
      end

      it "must raise if typeclass constraint is not satisfied" do
        _ { fn.call 1.0, 2.0 }.must_raise TypeError
      end
    end

    describe "method with multiple typeclass constraints" do
      let(:method_name) { :multiple_typeclass_constrained }

      it "must succeed if all typeclass constraints are satisfied" do
        _(fn.call Just["a"]).must_equal Maybe.return('"A"')
      end

      it "must raise if not all typeclass constraints are satisfied" do
        _ { fn.call ["a"] }.must_raise TypeError
      end
    end

    describe "method with typeclass constrainted return type" do
      let(:method_name) { :typeclass_constrained_return_type }

      it "must succeed if return typeclass constraint is satisfied" do
        _(fn.call 1).must_equal Either.return(1)
      end

      it "must raise if return typeclass constraint is not satisfied" do
        _ { fn.call 2 }.must_raise TypeError
      end
    end

    describe "curried" do
      let(:method_name) { :curried }

      describe "when all args passed it must act like uncurried" do
        it "must succeed if types are correct" do
          _(fn.call 1, 2.0).must_equal 1 + 2.0
        end

        it "must raise if types are incorrect" do
          _ { fn.call 1, 2.0.to_s }.must_raise TypeError
        end
      end

      describe "when not all args passed it must check passed args and return proc" do
        it "must succeed if types are correct" do
          _(fn.call 1).must_be_instance_of Proc
        end

        it "must raise if types are incorrect" do
          _ { fn.call 2.0 }.must_raise TypeError
        end

        it "must raise if arguments count is more than it should" do
          _ { fn.call 1, 2.0.to_s, 3 }.must_raise ArgumentError
        end
      end
    end
  end
end
