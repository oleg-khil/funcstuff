# frozen_string_literal: true

require "monad"

describe Maybe do
  describe "self.return" do
    let(:klass) { Maybe }

    describe "monad laws" do
      let(:monad) { Maybe }

      describe "left identity" do
        let(:a) { 2 }
        let(:h) { ->(x) { monad.return x * 2 }}

        it "is expected to satisfy" do
          _(monad.return(a).bind(&h)).must_equal h.call(a)
        end
      end

      describe "right identity" do
        let(:m) { monad.return 2 }

        it "is expected to satisfy" do
          _(m.bind(&monad.method(:return))).must_equal m
        end
      end

      describe "associativity" do
        let(:m) { monad.return 2 }
        let(:g) { ->(x) { monad.return x * 3 } }
        let(:h) { ->(x) { monad.return x ** 2 } }

        it "is expected to satisfy" do
          _(m.bind(&g).bind(&h)).must_equal m.bind { |x| g.call(x).bind(&h) }
        end
      end
    end

    it "is expected to wrap value in Just" do
      _(klass.return(1)).must_be_instance_of Just
      _(
        klass.return(1).__send__(:instance_variable_get, :@value)
      ).must_equal(1)
    end

    describe "bind" do
      describe "when value is Just" do
        let(:maybe_value) { Just[1] }

        it "is expected to pass value to block and execute block" do
          maybe_value.bind do
            _(_1).must_equal(1)

            maybe_value
          end
        end

        it "is expected to raise if block return value is not Maybe" do
          _ { maybe_value.bind { 1 } }.must_raise TypeError
        end
      end

      describe "when value is None" do
        let(:maybe_value) { None[] }

        it "is expected not to pass value to block and dont execute block" do
          run = false
          maybe_value.bind do
            run = true

            maybe_value
          end

          _(run).must_equal false
        end
      end
    end
  end

  describe Just do
    let(:klass) { Just }

    describe "[]" do
      it "is expected to wrap value" do
        _(klass[1]).must_be_instance_of Just
        _(klass[1].__send__(:instance_variable_get, :@value)).must_equal 1
      end
    end
  end

  describe None do
    let(:klass) { None }

    describe "[]" do
      it "is expected to return None instance" do
        _(klass[]).must_be_instance_of None
      end
    end
  end
end

describe Either do
  describe "self.return" do
    let(:klass) { Either }

    it "is expected to wrap value in Right" do
      _(klass.return(1)).must_be_instance_of Right
      _(
        klass.return(1).__send__(:instance_variable_get, :@value)
      ).must_equal(1)
    end

    describe "monad laws" do
      let(:monad) { Either }

      describe "left identity" do
        let(:a) { 2 }
        let(:h) { ->(x) { monad.return x * 2 }}

        it "is expected to satisfy" do
          _(monad.return(a).bind(&h)).must_equal h.call(a)
        end
      end

      describe "right identity" do
        let(:m) { monad.return 2 }

        it "is expected to satisfy" do
          _(m.bind(&monad.method(:return))).must_equal m
        end
      end

      describe "associativity" do
        let(:m) { monad.return 2 }
        let(:g) { ->(x) { monad.return x * 3 } }
        let(:h) { ->(x) { monad.return x ** 2 } }

        it "is expected to satisfy" do
          _(m.bind(&g).bind(&h)).must_equal m.bind { |x| g.call(x).bind(&h) }
        end
      end
    end

    describe "bind" do
      describe "when value is Right" do
        let(:maybe_value) { Right[1] }

        it "is expected to pass value to block and execute block" do
          maybe_value.bind do
            _(_1).must_equal(1)

            maybe_value
          end
        end

        it "is expected to raise if block return value is not Either" do
          _ { maybe_value.bind { 1 } }.must_raise TypeError
        end
      end

      describe "when value is Left" do
        let(:maybe_value) { Left[1] }

        it "is expected not to pass value to block and dont execute block" do
          run = false
          maybe_value.bind do
            run = true

            maybe_value
          end

          _(run).must_equal false
        end
      end
    end
  end

  describe Right do
    let(:klass) { Right }

    describe "[]" do
      it "is expected to wrap value" do
        _(klass[1]).must_be_instance_of Right
        _(klass[1].__send__(:instance_variable_get, :@value)).must_equal 1
      end
    end
  end

  describe Left do
    let(:klass) { Left }

    describe "[]" do
      it "is expected to return Left instance" do
        _(klass[1]).must_be_instance_of Left
        _(klass[1].__send__(:instance_variable_get, :@value)).must_equal 1
      end
    end
  end
end

describe Monad do
  describe "self.do" do
    it "is expected to return first failure" do
      run_before_failure = false
      run_after_failure = false
      result = Monad.do do |&bind|
        bind.(Right[1])
        run_before_failure= true
        bind.(Left[2])
        run_after_failure = true
        bind.(Right[3])

        Right[4]
      end

      _(run_before_failure).must_equal true
      _(run_after_failure).must_equal false
      _(result).must_be_instance_of Left
      _(
        result.__send__(:instance_variable_get, :@value)
      ).must_equal 2
    end

    it "is expected to return last expression if no failures happend" do
      run = false
      result = Monad.do do |&bind|
        bind.(Right[1])
        bind.(Right[2])
        run = true

        Right[3]
      end

      _(run).must_equal true
      _(result).must_be_instance_of Right
      _(
        result.__send__(:instance_variable_get, :@value)
      ).must_equal 3
    end

    it "is expected to raise if binded expression is not Monad" do
      _ {
        Monad.do do |&bind|
          bind.(1)

          2
        end
      }.must_raise TypeError
    end

    it "is expected to raise if last expression is not Monad" do
      _ {
        Monad.do do |&bind|
          bind.(Right[1])
          bind.(Right[2])

          3
        end
      }.must_raise TypeError
    end
  end
end

