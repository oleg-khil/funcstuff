# frozen_string_literal: true

require "let"

class ClassForTest
  def b
    1
  end

  def x
    10
  end

  def z
    123
  end

  def math
    Let.(:a) { 1 }
       .(:b) { 2 }
       .(:c) { x * 2 }
       .(:plus) { ->(v1, v2) { v1 + v2 } }
       .in { plus(a, b) + c + z }
  end
end

describe "Let" do
  describe "expression value" do
    let(:instance) { ClassForTest.new }

    it "must be correct" do
      _(Let.(:a) { 1 }.(:b) { 2 }.in { a + b }).must_equal 1 + 2
    end

    it "must not modify caller object" do
      _ { instance.a }.must_raise NameError
      _(instance.b).must_equal 1
      _ { instance.c }.must_raise NameError
      _(instance.x).must_equal 10
      _(instance.z).must_equal 123

      _(instance.math).must_equal 1 + 2 + (10 * 2) + 123

      _ { instance.a }.must_raise NameError
      _(instance.b).must_equal 1
      _ { instance.c }.must_raise NameError
      _(instance.x).must_equal 10
      _(instance.z).must_equal 123
    end
  end
end

