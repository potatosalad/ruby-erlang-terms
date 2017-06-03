# encoding: utf-8

require 'test_helper'

class Erlang::AtomTest < Minitest::Test

  def test_create
    lhs = Erlang::Atom[:test]
    assert_equal lhs, Erlang::Atom[:test]
    refute_equal lhs, Erlang::Atom[:bad]
    refute_equal lhs, Erlang::Atom[:test, utf8: true]
    assert_equal lhs, Erlang::Atom["test"]
    assert_equal lhs, Erlang::Atom["t", "e", :s, "t"]
    lhs = Erlang::Atom["\x00\xCE"]
    assert_equal lhs, Erlang::Atom[0, 206]
    refute_equal lhs, Erlang::Atom[0, 206, utf8: true]
    assert_raises(ArgumentError) { Erlang::Atom[Object.new] }
  end

  def test_compare
    lhs = Erlang::Atom[:a]
    rhs = Erlang::Atom["a"]
    assert_equal 0, Erlang::Atom.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::Atom[:a]
    rhs = Erlang::Atom[:b]
    assert_equal -1, Erlang::Atom.compare(lhs, rhs)
    assert_equal 1, Erlang::Atom.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_erlang_inspect
    assert_equal "'test'", Erlang::Atom[:test].erlang_inspect
    assert_equal "'test'", Erlang::Atom[:test, utf8: true].erlang_inspect
    assert_equal "'test'", Erlang.inspect(:test)
    assert_equal "'\\xCE\\xA9'", Erlang::Atom[:Ω].erlang_inspect
    assert_equal "'Ω'", Erlang::Atom[:Ω, utf8: true].erlang_inspect
    assert_equal "'true'", Erlang.inspect(true)
    assert_equal "'false'", Erlang.inspect(false)
    assert_equal "'nil'", Erlang.inspect(nil)
  end

  def test_inspect
    assert_equal ":test", Erlang::Atom[:test].inspect
    assert_equal ":Ω", Erlang::Atom[:Ω].inspect
    assert_equal "Erlang::Atom[\"Ω\", utf8: true]", Erlang::Atom[:Ω, utf8: true].inspect
    assert_equal "Erlang::Atom[\"\\x00\\xCE\"]", Erlang::Atom["\x00\xCE"].inspect
    assert_equal "Erlang::Atom[\"\\x00\\xCE\", utf8: true]", Erlang::Atom["\x00\xCE", utf8: true].inspect
    assert_equal "true", Erlang::Atom[true].inspect
    assert_equal "false", Erlang::Atom[false].inspect
    assert_equal "nil", Erlang::Atom[nil].inspect
  end

  def test_property_of_inspect
    property_of {
      random_erlang_atom
    }.check { |atom|
      assert_equal atom, eval(atom.inspect)
    }
  end

  def test_to_atom
    assert_equal Erlang::Atom["test"], Erlang::Atom["test"].to_atom
  end

  def test_to_binary
    assert_equal Erlang::Binary["test"], Erlang::Atom["test"].to_binary
  end

  def test_to_list
    assert_equal Erlang::List[116, 101, 115, 116], Erlang::Atom["test"].to_list
  end

  def test_to_string
    assert_equal Erlang::String["test"], Erlang::Atom["test"].to_string
  end

  def test_to_s
    assert_equal "test", Erlang::Atom["test"].to_s
  end

  def test_marshal
    lhs = Erlang::Atom[:test]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::Atom[:Ω]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::Atom[:Ω, utf8: true]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::Atom["\x00\xCE"]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::Atom["\x00\xCE", utf8: true]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::Atom[true]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::Atom[false]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::Atom[nil]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::Atom["test"], 1)
    map = map.put(:test, 2)
    assert_equal 2, map[Erlang::Atom["test"]]
  end

end
