# encoding: utf-8

require 'test_helper'

class Erlang::AssociableTest < Minitest::Test

  def test_update_in
    map = Erlang::Map[
      "A" => "aye",
      "B" => Erlang::Map["C" => "see", "D" => Erlang::Map["E" => "eee"]],
      "F" => Erlang::Tuple["G", Erlang::Map["H" => "eitch"], "I"]
    ]
    tuple = Erlang::Tuple[
      100,
      101,
      102,
      Erlang::Tuple[200, 201, Erlang::Tuple[300, 301, 302]],
      Erlang::Map["A" => "alpha", "B" => "bravo"],
      [400, 401, 402]
    ]
    # Context: with one level on existing key
    ## Map passes the value to the block
    map.update_in("A") { |value| assert_equal("aye", value) }
    ## Tuple passes the value to the block
    tuple.update_in(1) { |value| assert_equal(101, value) }
    ## Map replaces the value with the result of the block
    result = map.update_in("A") { |value| "FLIBBLE" }
    assert_equal "FLIBBLE", result.get("A")
    ## Tuple replaces the value with the result of the block
    result = tuple.update_in(1) { |value| "FLIBBLE" }
    assert_equal "FLIBBLE", result.get(1)
    ## Map should preserve the original
    result = map.update_in("A") { |value| "FLIBBLE" }
    assert_equal "aye", map.get("A")
    ## Tuple should preserve the original
    result = tuple.update_in(1) { |value| "FLIBBLE" }
    assert_equal 101, tuple.get(1)
    # Context: with multi-level on existing keys
    ## Map passes the value to the block
    map.update_in("B", "D", "E") { |value| assert_equal("eee", value) }
    ## Tuple passes the value to the block
    tuple.update_in(3, 2, 0) { |value| assert_equal(300, value) }
    ## Map replaces the value with the result of the block
    result = map.update_in("B", "D", "E") { |value| "FLIBBLE" }
    assert_equal "FLIBBLE", result["B"]["D"]["E"]
    ## Tuple replaces the value with the result of the block
    result = tuple.update_in(3, 2, 0) { |value| "FLIBBLE" }
    assert_equal "FLIBBLE", result[3][2][0]
    ## Map should preserve the original
    result = map.update_in("B", "D", "E") { |value| "FLIBBLE" }
    assert_equal "eee", map["B"]["D"]["E"]
    ## Tuple should preserve the original
    result = tuple.update_in(3, 2, 0) { |value| "FLIBBLE" }
    assert_equal 300, tuple[3][2][0]
    # Context: with multi-level creating sub-maps when keys don't exist
    ## Map passes nil to the block
    map.update_in("B", "X", "Y") { |value| assert value == nil }
    ## Tuple passes nil to the block
    tuple.update_in(3, 3, "X", "Y") { |value| assert value == nil }
    ## Map creates submaps on the way to set the value
    result = map.update_in("B", "X", "Y") { |value| "NEWVALUE" }
    assert_equal "NEWVALUE", result["B"]["X"]["Y"]
    assert_equal "eee", result["B"]["D"]["E"]
    ## Tuple creates submaps on the way to set the value
    result = tuple.update_in(3, 3, "X", "Y") { |value| "NEWVALUE" }
    assert_equal "NEWVALUE", result[3][3]["X"]["Y"]
    assert_equal 300, result[3][2][0]
    # Context: Map with multi-level including Tuple with existing keys
    ## passes the value to the block
    map.update_in("F", 1, "H") { |value| assert_equal("eitch", value) }
    ## replaces the value with the result of the block
    result = map.update_in("F", 1, "H") { |value| "FLIBBLE" }
    assert_equal "FLIBBLE", result["F"][1]["H"]
    ## should preserve the original
    result = map.update_in("F", 1, "H") { |value| "FLIBBLE" }
    assert_equal "eitch", map["F"][1]["H"]
    # Context: Tuple with multi-level including Map with existing keys
    ## passes the value to the block
    tuple.update_in(4, "B") { |value| assert_equal("bravo", value) }
    ## replaces the value with the result of the block
    result = tuple.update_in(4, "B") { |value| "FLIBBLE" }
    assert_equal "FLIBBLE", result[4]["B"]
    ## should preserve the original
    result = tuple.update_in(4, "B") { |value| "FLIBBLE" }
    assert_equal "bravo", tuple[4]["B"]
    # Context: with empty key_path
    ## Map raises ArgumentError
    assert_raises(ArgumentError) { map.update_in() { |v| 42 } }
    ## Tuple raises ArgumentError
    assert_raises(ArgumentError) { tuple.update_in() { |v| 42 } }
  end

  def test_dig
    # Context: Map
    m = Erlang::Map[:a => 9, :b => Erlang::Map[:c => 'a', :d => 4], :e => nil]
    ## returns the value with one argument to dig
    assert_equal 9, m.dig(:a)
    ## returns the value in nested maps
    assert_equal 'a', m.dig(:b, :c)
    ## returns nil if the key is not present
    assert m.dig(:f, :foo) == nil
    ## returns nil if you dig out the end of the map
    assert m.dig(:f, :foo, :bar) == nil
    ## returns nil if a value does not support dig
    assert m.dig(:a, :foo) == nil
    ## returns the correct value when there is a default proc
    default_map = Erlang::Map.new { |k| "#{k}-default" }
    assert_equal "a-default", default_map.dig(:a)
    # Context: Tuple
    t = Erlang::Tuple[1, 2, Erlang::Tuple[3, 4]]
    ## returns value at the index with one argument
    assert_equal 1, t.dig(0)
    ## returns value at index in nested arrays
    assert_equal 3, t.dig(2, 0)
    ## returns nil when indexing deeper than possible
    assert t.dig(0, 0) == nil
    ## returns nil if you index past the end of an array
    assert t.dig(5) == nil
    ## raises a type error when indexing with a key arrays don't understand
    assert_raises(ArgumentError) { t.dig(:foo) }
  end

end
