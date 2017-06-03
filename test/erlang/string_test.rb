# encoding: utf-8

require 'test_helper'

class Erlang::StringTest < Minitest::Test

  def test_create
    lhs = Erlang::String["test"]
    assert_equal lhs, Erlang::String["test"]
    refute_equal lhs, Erlang::String["bad"]
    assert_equal lhs, Erlang::List[116, 101, 115, 116]
    assert_equal lhs, Erlang::String["t", "e", :s, "t"]
    lhs = Erlang::String["\x00\xCE"]
    assert_equal lhs, Erlang::String[0, 206]
    assert_raises(ArgumentError) { Erlang::String[Object.new] }
  end

  def test_compare
    lhs = Erlang::String["a"]
    rhs = Erlang::String["a"]
    assert_equal 0, Erlang::String.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::String["a"]
    rhs = Erlang::String["b"]
    assert_equal -1, Erlang::String.compare(lhs, rhs)
    assert_equal 1, Erlang::String.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_empty?
    assert Erlang::String[].empty?
    assert Erlang::String[""].empty?
    refute Erlang::String["test"].empty?
  end

  def test_flatten
    assert_equal [""], Erlang::String[].flatten
    assert_equal ["test"], Erlang::String["test"].flatten
  end

  def test_erlang_inspect
    assert_equal "\"test\"", Erlang::String["test"].erlang_inspect
    assert_equal "\"\\xCE\\xA9\"", Erlang::String["Ω"].erlang_inspect
    assert_equal "[116,101,115,116]", Erlang::String["test"].erlang_inspect(true)
    assert_equal "[206,169]", Erlang::String["Ω"].erlang_inspect(true)
  end

  def test_inspect
    assert_equal "Erlang::String[\"test\"]", Erlang::String["test"].inspect
    assert_equal "Erlang::String[\"\\xCE\\xA9\"]", Erlang::String["Ω"].inspect
  end

  def test_property_of_inspect
    property_of {
      random_erlang_string
    }.check { |string|
      assert_equal string, eval(string.inspect)
    }
  end

  def test_to_atom
    assert_equal Erlang::Atom["test"], Erlang::String["test"].to_atom
  end

  def test_to_binary
    assert_equal Erlang::Binary["test"], Erlang::String["test"].to_binary
  end

  def test_to_list
    assert_equal Erlang::List[116, 101, 115, 116], Erlang::String["test"].to_list
  end

  def test_to_string
    assert_equal Erlang::String["test"], Erlang::String["test"].to_string
  end

  def test_to_s
    assert_equal "test", Erlang::String["test"].to_s
  end

  def test_marshal
    lhs = Erlang::String["test"]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::String["Ω"]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::String["test"], 1)
    map = map.put(Erlang::List[116, 101, 115, 116], 2)
    assert_equal 2, map[Erlang::String["test"]]
  end

end
