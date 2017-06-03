# encoding: utf-8

require 'test_helper'

class Erlang::TupleTest < Minitest::Test

  def test_create
    lhs = Erlang::Tuple[:a, 0]
    assert_equal lhs, Erlang::Tuple[:a, 0]
    refute_equal lhs, Erlang::Tuple[:a, 1]
    refute_equal lhs, Erlang::Tuple[:a, 0, 0]
    refute_equal lhs, Erlang::Tuple[]
    assert_raises(ArgumentError) { Erlang::Tuple[:a, Object.new] }
  end

  def test_compare
    lhs = Erlang::Tuple[:a, 0]
    rhs = Erlang::Tuple[:a, 0]
    assert_equal 0, Erlang::Tuple.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::Tuple[:a, 0]
    rhs = Erlang::Tuple[:a, 1]
    assert_equal -1, Erlang::Tuple.compare(lhs, rhs)
    assert_equal 1, Erlang::Tuple.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_erlang_inspect
    assert_equal "{'a',0}", Erlang::Tuple[:a, 0].erlang_inspect
    assert_equal "{'a',0}", Erlang.inspect(Erlang::Tuple[:a, 0])
  end

  def test_inspect
    assert_equal "Erlang::Tuple[:a, 0]", Erlang::Tuple[:a, 0].inspect
  end

  def test_property_of_inspect
    property_of {
      random_erlang_tuple
    }.check { |tuple|
      assert_equal tuple, eval(tuple.inspect)
    }
  end

  def test_property_of_marshal
    property_of {
      random_erlang_tuple
    }.check { |tuple|
      assert_equal tuple, Marshal.load(Marshal.dump(tuple))
    }
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::Tuple[:a, 0], 1)
    map = map.put(Erlang::Tuple[:a, 0], 2)
    assert_equal 2, map[Erlang::Tuple[:a, 0]]
  end

end
