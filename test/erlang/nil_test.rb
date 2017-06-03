# encoding: utf-8

require 'test_helper'

class Erlang::NilTest < Minitest::Test

  def test_create
    lhs = Erlang::Nil
    assert_equal lhs, Erlang::Nil
    refute_equal lhs, Erlang::List[Erlang::Nil]
    assert_equal lhs, Erlang::List[]
  end

  def test_compare
    lhs = Erlang::Nil
    rhs = Erlang::Nil
    assert_equal 0, Erlang::List.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::List[]
    rhs = Erlang::List[0]
    assert_equal -1, Erlang::List.compare(lhs, rhs)
    assert_equal 1, Erlang::List.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_erlang_inspect
    assert_equal "[]", Erlang.inspect(Erlang::Nil)
    assert_equal "[]", Erlang.inspect(Erlang::List[])
  end

  def test_inspect
    assert_equal "[]", Erlang::Nil.inspect
  end

  def test_marshal
    lhs = Erlang::Nil
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::Nil, 1)
    map = map.put(Erlang::List[], 2)
    assert_equal 2, map[Erlang::Nil]
  end

  def test_head
    assert_equal Erlang::Undefined, Erlang::Nil.head
  end

  def test_tail
    assert_equal Erlang::Nil, Erlang::Nil.tail
  end

  def test_empty?
    assert_equal true, Erlang::Nil.empty?
  end

  def test_improper?
    assert_equal false, Erlang::Nil.improper?
  end

  def test_size
    assert_equal 0, Erlang::Nil.size
  end

end
