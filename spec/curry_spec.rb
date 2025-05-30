# frozen_string_literal: true

require "curry"

class ClassForTest
  extend Curry

  curry_self def self.pluss(a, b)
    a + b
  end

  curry_instance def plusi(a, b)
    a + b
  end
end

describe Curry do
  describe "curry_self" do
    it "must curry self methods" do
      _(ClassForTest.pluss(1)).must_be_instance_of Proc
    end
  end

  describe "curry_instance" do
    it "must curry instance methods" do
      _(ClassForTest.new.plusi(1)).must_be_instance_of Proc
    end
  end
end

