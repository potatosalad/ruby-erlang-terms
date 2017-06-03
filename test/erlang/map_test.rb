# encoding: utf-8

require 'test_helper'

class Erlang::MapTest < Minitest::Test

  def test_create
    lhs = Erlang::Map[:a, 0]
    assert_equal lhs, Erlang::Map[:a => 0]
    refute_equal lhs, Erlang::Map[:a, 1]
    refute_equal lhs, Erlang::Map[]
    assert_equal lhs, Erlang::Map[a: 0]
    assert_raises(ArgumentError) { Erlang::Map[:a, Object.new] }
  end

  def test_compare
    lhs = Erlang::Map[:a, 0]
    rhs = Erlang::Map[:a, 0]
    assert_equal 0, Erlang::Map.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::Map[:a, 0]
    rhs = Erlang::Map[:a, 1]
    assert_equal -1, Erlang::Map.compare(lhs, rhs)
    assert_equal 1, Erlang::Map.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_erlang_inspect
    assert_equal "\#{'a' => 0}", Erlang::Map[:a, 0].erlang_inspect
    assert_equal "\#{'a' => 0}", Erlang.inspect(Erlang::Map[:a, 0])
  end

  def test_inspect
    assert_equal "{:a => 0}", Erlang::Map[:a, 0].inspect
  end

  def test_property_of_inspect
    property_of {
      random_erlang_map
    }.check { |map|
      assert_equal map, eval(map.inspect)
    }
  end

  def test_property_of_marshal
    property_of {
      random_erlang_map
    }.check { |map|
      assert_equal map, Marshal.load(Marshal.dump(map))
    }
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::Map[:a, 0], 1)
    map = map.put(Erlang::Map[:a, 0], 2)
    assert_equal 2, map[Erlang::Map[:a, 0]]
  end

end
