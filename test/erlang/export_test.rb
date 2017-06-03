# encoding: utf-8

require 'test_helper'

class Erlang::ExportTest < Minitest::Test

  def test_create
    lhs = Erlang::Export[:erlang, :make_ref, 0]
    assert_equal lhs, Erlang::Export[:erlang, :make_ref, 0]
    refute_equal lhs, Erlang::Export[:erlang, :make_ref, 1]
    assert_equal lhs, Erlang::Export["erlang", "make_ref", 0]
    assert_raises(ArgumentError) { Erlang::Export[:erlang, :make_ref, 0.0] }
    assert_raises(ArgumentError) { Erlang::Export[Object.new, :make_ref, 0.0] }
  end

  def test_compare
    lhs = Erlang::Export[:erlang, :make_ref, 0]
    rhs = Erlang::Export[:erlang, :make_ref, 0]
    assert_equal 0, Erlang::Export.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::Export[:erlang, :make_ref, 0]
    rhs = Erlang::Export[:erlang, :make_ref, 1]
    assert_equal -1, Erlang::Export.compare(lhs, rhs)
    assert_equal 1, Erlang::Export.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_erlang_inspect
    assert_equal "fun 'erlang':'make_ref'/0", Erlang::Export[:erlang, :make_ref, 0].erlang_inspect
    assert_equal "fun 'erlang':'make_ref'/0", Erlang.inspect(Erlang::Export[:erlang, :make_ref, 0])
  end

  def test_inspect
    assert_equal "Erlang::Export[:erlang, :make_ref, 0]", Erlang::Export[:erlang, :make_ref, 0].inspect
  end

  def test_property_of_inspect
    property_of {
      random_erlang_export
    }.check { |export|
      assert_equal export, eval(export.inspect)
    }
  end

  def test_marshal
    lhs = Erlang::Export[:erlang, :make_ref, 0]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::Export[:erlang, :make_ref, 0], 1)
    map = map.put(Erlang::Export[:erlang, :make_ref, 0], 2)
    assert_equal 2, map[Erlang::Export[:erlang, :make_ref, 0]]
  end

end
