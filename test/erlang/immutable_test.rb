# encoding: utf-8

require 'test_helper'

class Erlang::ImmutableTest < Minitest::Test

  class Fixture0
    include Erlang::Immutable
  end

  def test_copying
    lhs = Fixture0.new
    rhs = lhs.clone
    assert_equal lhs, rhs
    rhs = lhs.dup
    assert_equal lhs, rhs
  end

  def test_immutable?
    # object constructed after its class becomes Immutable
    fixture = Fixture0.new
    assert fixture.immutable?
    # object constructed before its class becomes Immutable
    fixture = Class.new.new
    fixture.class.instance_eval do
      include Erlang::Immutable
    end
    refute fixture.immutable?
    fixture.freeze
    assert fixture.immutable?
  end

  class Fixture1
    include Erlang::Immutable

    def initialize(&block)
      @block = block
    end

    def call
      return @block.call
    end
    memoize :call

    def copy
      return transform {}
    end
  end

  def test_memoize
    count = 0
    fixture = Fixture1.new { count += 1 }
    fixture.call
    assert fixture.immutable?
    fixture.call
    assert_equal 1, count
    copy = fixture.copy
    copy.call
    assert_equal 2, count
  end

  class NewPerson < Struct.new(:first, :last)
    include Erlang::Immutable
  end

  def test_new
    immutable = NewPerson.new("Simon", "Harris")
    assert immutable.frozen?
    my_class = Class.new do
      include Erlang::Immutable

      (public_instance_methods - Object.public_instance_methods).each do |m|
        protected m
      end
    end
    immutable = my_class.new
    assert immutable.frozen?
  end

  class TransformPerson < Struct.new(:first, :last)
    include Erlang::Immutable

    public :transform
  end

  def test_transform
    immutable = TransformPerson.new("Simon", "Harris")
    transform = immutable.transform { self.first = "Sampy" }
    assert_equal "Simon", immutable.first
    assert_equal "Sampy", transform.first
  end

  class TransformUnlessPerson < Struct.new(:first, :last)
    include Erlang::Immutable

    public :transform_unless
  end

  def test_transform_unless
    immutable = TransformUnlessPerson.new("Simon", "Harris")
    transform = immutable.transform_unless(false) { |thing| self.first = "Sampy" }
    assert_equal "Simon", immutable.first
    assert_equal "Sampy", transform.first
    transform = immutable.transform_unless(true) { |thing| self.first = "Sampy" }
    assert_equal "Simon", immutable.first
    assert_equal "Simon", transform.first
  end

end
