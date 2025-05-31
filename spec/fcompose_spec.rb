# frozen_string_literal: true

describe "F" do
  describe "expression value" do
    let(:array) { (123..321).to_a }

    describe "without methods called" do
      it "must be identity function" do
        _(F.call(123)).must_equal 123
        _(array.map(&F)).must_equal array
      end
    end

    describe "with one method called" do
      let(:func) { F.to_s }

      it "must apply this method" do
        _(func.call 123).must_equal 123.to_s
        _(array.map(&func)).must_equal array.map(&:to_s)
      end
    end

    describe "with many methods called" do
      let(:func) { F.to_s.to_sym }

      it "must apply this methods in order" do
        _(func.call 123).must_equal 123.to_s.to_sym
        _(array.map(&func)).must_equal array.map(&:to_s).map(&:to_sym)
      end
    end

    describe "with many methods and proc called" do
      let(:func) { F.to_s.to_sym >> -> { _1.to_s.to_i ** 2 } }

      it "must apply this methods and proc in order" do
        _(func.call 123).must_equal 15129
        _(array.map(&func)).must_equal array.map(&:to_s).map(&:to_sym).map { _1.to_s.to_i ** 2 }
      end
    end
  end
end
