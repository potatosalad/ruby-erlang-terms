# encoding: utf-8

require 'test_helper'

class Erlang::FloatTest < Minitest::Test

  def test_create
    lhs = Erlang::Float[0]
    assert_equal lhs, Erlang::Float[0]
    refute_equal lhs, Erlang::Float[1]
    assert_raises(ArgumentError) { Erlang::Float[Object.new] }
  end

  def test_compare
    lhs = Erlang::Float[0]
    rhs = Erlang::Float[0]
    assert_equal 0, Erlang::Float.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::Float[0]
    rhs = Erlang::Float[1]
    assert_equal -1, Erlang::Float.compare(lhs, rhs)
    assert_equal 1, Erlang::Float.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_erlang_inspect
    assert_equal "0.00000000000000000000e+00", Erlang::Float[0].erlang_inspect
    assert_equal "0.00000000000000000000e+00", Erlang.inspect(Erlang::Float[0])
  end

  def test_inspect
    assert_equal "0.00000000000000000000e+00", Erlang::Float[0].inspect
  end

  def test_property_of_inspect
    property_of {
      random_erlang_float
    }.check { |float|
      assert_equal float, eval(float.inspect)
    }
  end

  def test_property_of_marshal
    property_of {
      random_erlang_float
    }.check { |float|
      assert_equal float, Marshal.load(Marshal.dump(float))
    }
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::Float[0], 1)
    map = map.put(Erlang::Float[0], 2)
    assert_equal 2, map[Erlang::Float[0]]
  end

end
