# frozen_string_literal: true

require "functor"

describe "Functor" do
  describe "with Maybe" do
    let(:just) { Just[1] }

    describe "when value is Just" do
      it "must call block and wrap result in Just" do
        run = false
        result = just.fmap do
          run = true
          _1.to_s
        end
        _(result).must_be_instance_of Just
        _(result.__send__(:instance_variable_get, :@value)).must_equal 1.to_s
        _(run).must_equal true
      end
    end

    describe "when value is None" do
      it "must not call block and return initial value" do
        run = false
        result = None[].fmap do
          run = true
          _1.to_s
        end
        _(result).must_be_instance_of None
        _(run).must_equal false
      end
    end
  end

  describe "with Either" do
    let(:right) { Right[1] }
    let(:left) { Left[2] }

    describe "when value is Right" do
      it "must call block and wrap result in Right" do
        run = false
        result = right.fmap do
          run = true
          _1.to_s
        end
        _(result).must_be_instance_of Right
        _(result.__send__(:instance_variable_get, :@value)).must_equal 1.to_s
        _(run).must_equal true
      end
    end

    describe "when value is Left" do
      it "must not call block and return initial value" do
        run = false
        result = left.fmap do
          run = true
          _1.to_s
        end
        _(result).must_be_instance_of Left
        _(result.__send__(:instance_variable_get, :@value)).must_equal 2
        _(run).must_equal false
      end
    end
  end
end

