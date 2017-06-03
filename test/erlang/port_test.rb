# encoding: utf-8

require 'test_helper'

class Erlang::PortTest < Minitest::Test

  def test_create
    lhs = Erlang::Port[:"nonode@nohost", 100, 1]
    assert_equal lhs, Erlang::Port[:"nonode@nohost", 100, 1]
    refute_equal lhs, Erlang::Port[:"nonode@nohost", 100, 2]
    assert_equal lhs, Erlang::Port["nonode@nohost", 100, 1]
    assert_raises(ArgumentError) { Erlang::Port[:"nonode@nohost", 100, 1.0] }
    assert_raises(ArgumentError) { Erlang::Port[Object.new, 100, 1] }
  end

  def test_compare
    lhs = Erlang::Port[:"nonode@nohost", 100, 1]
    rhs = Erlang::Port[:"nonode@nohost", 100, 1]
    assert_equal 0, Erlang::Port.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::Port[:"nonode@nohost", 100, 1]
    rhs = Erlang::Port[:"nonode@nohost", 100, 2]
    assert_equal -1, Erlang::Port.compare(lhs, rhs)
    assert_equal 1, Erlang::Port.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_erlang_inspect
    assert_equal "{'port','nonode@nohost',100,1}", Erlang::Port[:"nonode@nohost", 100, 1].erlang_inspect
    assert_equal "{'port','nonode@nohost',100,1}", Erlang.inspect(Erlang::Port[:"nonode@nohost", 100, 1])
  end

  def test_inspect
    assert_equal "Erlang::Port[:\"nonode@nohost\", 100, 1]", Erlang::Port[:"nonode@nohost", 100, 1].inspect
  end

  def test_property_of_inspect
    property_of {
      random_erlang_port
    }.check { |port|
      assert_equal port, eval(port.inspect)
    }
  end

  def test_marshal
    lhs = Erlang::Port[:"nonode@nohost", 100, 1]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::Port[:"nonode@nohost", 100, 1], 1)
    map = map.put(Erlang::Port[:"nonode@nohost", 100, 1], 2)
    assert_equal 2, map[Erlang::Port[:"nonode@nohost", 100, 1]]
  end

end
