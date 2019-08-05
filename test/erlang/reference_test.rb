# encoding: utf-8

require 'test_helper'

class Erlang::ReferenceTest < Minitest::Test

  def test_create
    lhs = Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]]
    assert lhs.newer_reference?
    refute lhs.new_reference?
    assert_raises(Erlang::NewerReferenceError) { lhs.id }
    assert_equal lhs, Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]]
    refute_equal lhs, Erlang::Reference[:"nonode@nohost", 0, [0, 0, 1]]
    assert_equal lhs, Erlang::Reference["nonode@nohost", 0, [0, 0, 0]]
    lhs = Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0], newer_reference: false]
    refute lhs.newer_reference?
    assert lhs.new_reference?
    assert_raises(Erlang::NewReferenceError) { lhs.id }
    assert_equal lhs, Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]]
    refute_equal lhs, Erlang::Reference[:"nonode@nohost", 0, [0, 0, 1]]
    assert_equal lhs, Erlang::Reference["nonode@nohost", 0, [0, 0, 0]]
    lhs = Erlang::Reference[:"nonode@nohost", 0, 0]
    refute lhs.newer_reference?
    refute lhs.new_reference?
    assert_equal 0, lhs.id
    assert_equal lhs, Erlang::Reference[:"nonode@nohost", 0, 0]
    refute_equal lhs, Erlang::Reference[:"nonode@nohost", 0, 1]
    assert_equal lhs, Erlang::Reference["nonode@nohost", 0, 0]
    assert_raises(ArgumentError) { Erlang::Reference[:"nonode@nohost", 0, 0.0] }
    assert_raises(ArgumentError) { Erlang::Reference[:"nonode@nohost", 0, [0.0]] }
    assert_raises(ArgumentError) { Erlang::Reference[Object.new, 0, 0] }
  end

  def test_compare
    lhs = Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]]
    rhs = Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]]
    assert_equal 0, Erlang::Reference.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]]
    rhs = Erlang::Reference[:"nonode@nohost", 0, [0, 0, 1]]
    assert_equal -1, Erlang::Reference.compare(lhs, rhs)
    assert_equal 1, Erlang::Reference.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
    lhs = Erlang::Reference[:"nonode@nohost", 0, 0]
    rhs = Erlang::Reference[:"nonode@nohost", 0, 0]
    assert_equal 0, Erlang::Reference.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::Reference[:"nonode@nohost", 0, 0]
    rhs = Erlang::Reference[:"nonode@nohost", 0, 1]
    assert_equal -1, Erlang::Reference.compare(lhs, rhs)
    assert_equal 1, Erlang::Reference.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_erlang_inspect
    assert_equal "{'reference','nonode@nohost',0,[0,0,0]}", Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]].erlang_inspect
    assert_equal "{'reference','nonode@nohost',0,[0,0,0]}", Erlang.inspect(Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]])
    assert_equal "{'reference','nonode@nohost',0,[0,0,0],'false'}", Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0], newer_reference: false].erlang_inspect
    assert_equal "{'reference','nonode@nohost',0,[0,0,0],'false'}", Erlang.inspect(Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0], newer_reference: false])
    assert_equal "{'reference','nonode@nohost',0,0}", Erlang::Reference[:"nonode@nohost", 0, 0].erlang_inspect
    assert_equal "{'reference','nonode@nohost',0,0}", Erlang.inspect(Erlang::Reference[:"nonode@nohost", 0, 0])
  end

  def test_inspect
    assert_equal "Erlang::Reference[:\"nonode@nohost\", 0, [0, 0, 0]]", Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]].inspect
    assert_equal "Erlang::Reference[:\"nonode@nohost\", 0, [0, 0, 0], newer_reference: false]", Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0], newer_reference: false].inspect
    assert_equal "Erlang::Reference[:\"nonode@nohost\", 0, 0]", Erlang::Reference[:"nonode@nohost", 0, 0].inspect
  end

  def test_property_of_inspect
    property_of {
      random_erlang_reference
    }.check { |reference|
      assert_equal reference, eval(reference.inspect)
    }
  end

  def test_marshal
    lhs = Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0], newer_reference: false]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::Reference[:"nonode@nohost", 0, 0]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]], 1)
    map = map.put(Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]], 2)
    map = map.put(Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0], newer_reference: false], 3)
    assert_equal 3, map[Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]]]
    map = Erlang::Map[]
    map = map.put(Erlang::Reference[:"nonode@nohost", 0, 0], 1)
    map = map.put(Erlang::Reference[:"nonode@nohost", 0, 0], 2)
    assert_equal 2, map[Erlang::Reference[:"nonode@nohost", 0, 0]]
  end

end
