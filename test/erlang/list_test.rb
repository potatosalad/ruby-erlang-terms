# encoding: utf-8

require 'test_helper'

class Erlang::ListTest < Minitest::Test

  def test_create
    lhs = Erlang::List[:a, 0]
    assert_equal lhs, Erlang::List[:a, 0]
    refute_equal lhs, Erlang::List[:a, 1]
    refute_equal lhs, Erlang::List[:a, 0, 0]
    refute_equal lhs, Erlang::List[]
    assert_raises(ArgumentError) { Erlang::List[:a, Object.new] }
  end

  def test_compare
    lhs = Erlang::List[:a, 0]
    rhs = Erlang::List[:a, 0]
    assert_equal 0, Erlang::List.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::List[:a, 0]
    rhs = Erlang::List[:a, 1]
    assert_equal -1, Erlang::List.compare(lhs, rhs)
    assert_equal 1, Erlang::List.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_erlang_inspect
    assert_equal "['a',0]", Erlang::List[:a, 0].erlang_inspect
    assert_equal "['a',0]", Erlang.inspect(Erlang::List[:a, 0])
  end

  def test_inspect
    assert_equal "[:a, 0]", Erlang::List[:a, 0].inspect
  end

  def test_property_of_inspect
    property_of {
      random_erlang_list
    }.check { |list|
      assert_equal list, eval(list.inspect)
    }
  end

  def test_property_of_marshal
    property_of {
      random_erlang_list
    }.check { |list|
      assert_equal list, Marshal.load(Marshal.dump(list))
    }
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::List[:a, 0], 1)
    map = map.put(Erlang::List[:a, 0], 2)
    assert_equal 2, map[Erlang::List[:a, 0]]
  end

end
