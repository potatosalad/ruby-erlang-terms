# encoding: utf-8

require 'test_helper'

class Erlang::BinaryTest < Minitest::Test

  def test_create
    lhs = Erlang::Binary["test"]
    assert_equal 8, lhs.bits
    assert_equal lhs, Erlang::Binary["test"]
    refute_equal lhs, Erlang::Binary["bad"]
    assert_equal lhs, Erlang::Binary[116, 101, 115, 116]
    assert_equal lhs, Erlang::Binary["t", "e", :s, "t"]
    lhs = Erlang::Binary["\x00\xCE"]
    assert_equal lhs, Erlang::Binary[0, 206]
    assert_raises(ArgumentError) { Erlang::Binary[Object.new] }
  end

  def test_compare
    lhs = Erlang::Binary["a"]
    rhs = Erlang::Binary["a"]
    assert_equal 0, Erlang::Binary.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::Binary["a"]
    rhs = Erlang::Binary["b"]
    assert_equal -1, Erlang::Binary.compare(lhs, rhs)
    assert_equal 1, Erlang::Binary.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_at
    b = Erlang::Binary[1,2,3]
    assert_equal 1, b.at(0)
    assert_equal 3, b.at(-1)
    assert_raises(ArgumentError) { b.at(1.0) }
  end

  def test_bitsize
    b = Erlang::Binary[1,2,3]
    assert_equal 24, b.bitsize
  end

  def test_bitslice
    c  = Erlang::Binary["c"]
    c3 = Erlang::Bitstring[3, bits: 3]
    c5 = Erlang::Bitstring[3, bits: 5]
    assert_equal c3, c.bitslice(0, 3)
    assert_equal c5, c.bitslice(3, 5)
    assert_equal c3, c.bitslice(0...3)
    assert_equal c5, c.bitslice(3...8)
    assert_equal 0, Erlang::Binary[1].bitslice(0)
    assert_equal 1, Erlang::Binary[1].bitslice(7)
    assert_equal 1, Erlang::Binary[1].bitslice(-1)
    assert_nil Erlang::Binary[1].bitslice(8)
  end

  def test_bytesize
    b = Erlang::Binary[1,2,3]
    assert_equal 3, b.bytesize
  end

  def test_concat
    a   = Erlang::Binary["a"]
    b   = Erlang::Binary["b"]
    c   = Erlang::Binary["c"]
    c3  = Erlang::Bitstring[3, bits: 3]
    c5  = Erlang::Bitstring[3, bits: 5]
    ab  = Erlang::Binary["ab"]
    abc = Erlang::Binary["abc"]
    assert_equal ab, Erlang::Binary.concat(a, b)
    assert_equal ab, a.concat(b)
    assert_equal abc, Erlang::Binary.concat(a, b, c3, c5)
    assert_equal abc, a.concat(b).concat(c3).concat(c5)
    assert_equal abc, ab.concat("c")
    assert_equal c, (c3 + c5)
  end

  def test_property_of_concat
    property_of {
      random_erlang_binary
    }.check { |binary|
      number = SecureRandom.random_number((binary.bitsize == 0) ? 1 : binary.bitsize) + 1
      assert_equal binary, Erlang::Binary.concat(*binary.each_bitslice(number))
    }
  end

  def test_copy
    rhs = Erlang::Binary[1,2,3]
    lhs = Erlang::Binary[1,2,3,1,2,3]
    assert_equal rhs, rhs.copy
    assert_equal lhs, rhs.copy(2)
  end

  def test_decode_unsigned
    s  = Erlang::Terms.binary_encoding("\x01\x00\x00\x00")
    b  = Erlang::Binary[1,0,0,0]
    le = 0x0000001
    be = 0x1000000
    assert_equal be, Erlang::Binary.decode_unsigned(b)
    assert_equal be, Erlang::Binary.decode_unsigned(s, :big)
    assert_equal le, Erlang::Binary.decode_unsigned(s, :little)
    assert_equal be, b.decode_unsigned
    assert_equal be, b.decode_unsigned(:big)
    assert_equal le, b.decode_unsigned(:little)
    assert_raises(ArgumentError) { Erlang::Binary.decode_unsigned(Object.new) }
    assert_raises(ArgumentError) { Erlang::Binary.decode_unsigned(s, :bad) }
  end

  def test_each_bit
    binary = Erlang::Binary[127, 0, 254]
    bits = [0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,0]
    enum = binary.each_bit
    assert enum.is_a?(Enumerator)
    assert_equal bits, enum.to_a
    array = []
    binary.each_bit { |bit| array.push(bit) }
    assert_equal bits, array
  end

  def test_each_bitslice
    b  = Erlang::Binary[117, 254, 1, 115]
    b8 = [
      Erlang::Binary[117],
      Erlang::Binary[254],
      Erlang::Binary[1],
      Erlang::Binary[115]
    ]
    b7 = [
      Erlang::Bitstring[58, bits: 7],
      Erlang::Bitstring[127, bits: 7],
      Erlang::Bitstring[64, bits: 7],
      Erlang::Bitstring[23, bits: 7],
      Erlang::Bitstring[3, bits: 4]
    ]
    b6 = [
      Erlang::Bitstring[29, bits: 6],
      Erlang::Bitstring[31, bits: 6],
      Erlang::Bitstring[56, bits: 6],
      Erlang::Bitstring[1, bits: 6],
      Erlang::Bitstring[28, bits: 6],
      Erlang::Bitstring[3, bits: 2]
    ]
    b5 = [
      Erlang::Bitstring[14, bits: 5],
      Erlang::Bitstring[23, bits: 5],
      Erlang::Bitstring[31, bits: 5],
      Erlang::Bitstring[0, bits: 5],
      Erlang::Bitstring[2, bits: 5],
      Erlang::Bitstring[28, bits: 5],
      Erlang::Bitstring[3, bits: 2]
    ]
    b4 = [
      Erlang::Bitstring[7, bits: 4],
      Erlang::Bitstring[5, bits: 4],
      Erlang::Bitstring[15, bits: 4],
      Erlang::Bitstring[14, bits: 4],
      Erlang::Bitstring[0, bits: 4],
      Erlang::Bitstring[1, bits: 4],
      Erlang::Bitstring[7, bits: 4],
      Erlang::Bitstring[3, bits: 4]
    ]
    b3 = [
      Erlang::Bitstring[3, bits: 3],
      Erlang::Bitstring[5, bits: 3],
      Erlang::Bitstring[3, bits: 3],
      Erlang::Bitstring[7, bits: 3],
      Erlang::Bitstring[7, bits: 3],
      Erlang::Bitstring[0, bits: 3],
      Erlang::Bitstring[0, bits: 3],
      Erlang::Bitstring[1, bits: 3],
      Erlang::Bitstring[3, bits: 3],
      Erlang::Bitstring[4, bits: 3],
      Erlang::Bitstring[3, bits: 2]
    ]
    b2 = [
      Erlang::Bitstring[1, bits: 2],
      Erlang::Bitstring[3, bits: 2],
      Erlang::Bitstring[1, bits: 2],
      Erlang::Bitstring[1, bits: 2],
      Erlang::Bitstring[3, bits: 2],
      Erlang::Bitstring[3, bits: 2],
      Erlang::Bitstring[3, bits: 2],
      Erlang::Bitstring[2, bits: 2],
      Erlang::Bitstring[0, bits: 2],
      Erlang::Bitstring[0, bits: 2],
      Erlang::Bitstring[0, bits: 2],
      Erlang::Bitstring[1, bits: 2],
      Erlang::Bitstring[1, bits: 2],
      Erlang::Bitstring[3, bits: 2],
      Erlang::Bitstring[0, bits: 2],
      Erlang::Bitstring[3, bits: 2]
    ]
    b1 = [
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[0, bits: 1],
      Erlang::Bitstring[1, bits: 1],
      Erlang::Bitstring[1, bits: 1]
    ]
    assert_equal b8, b.each_bitslice(8).to_a
    assert_equal b7, b.each_bitslice(7).to_a
    assert_equal b6, b.each_bitslice(6).to_a
    assert_equal b5, b.each_bitslice(5).to_a
    assert_equal b4, b.each_bitslice(4).to_a
    assert_equal b3, b.each_bitslice(3).to_a
    assert_equal b2, b.each_bitslice(2).to_a
    assert_equal b1, b.each_bitslice(1).to_a
    assert_raises(ArgumentError) { b.each_bitslice(0).to_a }
  end

  def test_each_byte
    binary = Erlang::Binary[127, 0, 254]
    bytes = [127,0,254]
    enum = binary.each_byte
    assert enum.is_a?(Enumerator)
    assert_equal bytes, enum.to_a
    array = []
    binary.each_byte { |byte| array.push(byte) }
    assert_equal bytes, array
  end

  def test_empty?
    assert Erlang::Binary[].empty?
    assert Erlang::Binary[""].empty?
    refute Erlang::Binary["test"].empty?
  end

  def test_encode_unsigned
    sbe = Erlang::Terms.binary_encoding("\x01\x00\x00\x00")
    sle = Erlang::Terms.binary_encoding("\x00\x00\x00\x01")
    i   = 0x1000000
    assert_equal sbe, Erlang::Binary.encode_unsigned(i)
    assert_equal sbe, Erlang::Binary.encode_unsigned(i, :big)
    assert_equal sle, Erlang::Binary.encode_unsigned(i, :little)
    assert_raises(ArgumentError) { Erlang::Binary.encode_unsigned(Object.new) }
    assert_raises(ArgumentError) { Erlang::Binary.encode_unsigned(i, :bad) }
  end

  def test_first
    assert_equal 1, Erlang::Binary[1, 2].first
    assert_raises(NotImplementedError) { Erlang::Binary[].first }
  end

  def test_last
    assert_equal 2, Erlang::Binary[1, 2].last
    assert_raises(NotImplementedError) { Erlang::Binary[].last }
  end

  def test_part
    b = Erlang::Binary["abcd"]
    assert_equal Erlang::Binary["abcd"], b.part(0, 4)
    assert_equal Erlang::Binary["abc"], b.part(0, 3)
    assert_equal Erlang::Binary["a"], b.part(0, 1)
    assert_equal Erlang::Binary[], b.part(0, 0)
    assert_equal Erlang::Binary["d"], b.part(-1, 1)
  end

  def test_erlang_inspect
    assert_equal "<<\"test\"/utf8>>", Erlang::Binary["test"].erlang_inspect
    assert_equal "<<\"Ω\"/utf8>>", Erlang::Binary["Ω"].erlang_inspect
    assert_equal "<<0,206>>", Erlang::Binary["\x00\xCE"].erlang_inspect
    assert_equal "<<116,101,115,116>>", Erlang::Binary["test"].erlang_inspect(true)
    assert_equal "<<206,169>>", Erlang::Binary["Ω"].erlang_inspect(true)
  end

  def test_inspect
    assert_equal "\"test\"", Erlang::Binary["test"].inspect
    assert_equal "\"Ω\"", Erlang::Binary["Ω"].inspect
    assert_equal "\"\\x00\\xCE\"", Erlang::Binary["\x00\xCE"].inspect
  end

  def test_property_of_inspect
    property_of {
      random_erlang_binary
    }.check { |binary|
      assert_equal binary, eval(binary.inspect)
    }
  end

  def test_to_atom
    assert_equal Erlang::Atom["test"], Erlang::Binary["test"].to_atom
  end

  def test_to_binary
    assert_equal Erlang::Binary["test"], Erlang::Binary["test"].to_binary
  end

  def test_to_bitstring
    assert_equal Erlang::Binary["test"], Erlang::Binary["test"].to_bitstring
    assert_equal Erlang::Bitstring["test", bits: 3], Erlang::Binary["test"].to_bitstring(3)
    assert_raises(ArgumentError) { Erlang::Binary["test"].to_bitstring(-1) }
  end

  def test_to_list
    assert_equal Erlang::List[116, 101, 115, 116], Erlang::Binary["test"].to_list
  end

  def test_to_string
    assert_equal Erlang::String["test"], Erlang::Binary["test"].to_string
  end

  def test_to_s
    assert_equal "test", Erlang::Binary["test"].to_s
  end

  def test_marshal
    lhs = Erlang::Binary["test"]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::Binary["Ω"]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::Binary["test"], 1)
    map = map.put(Erlang::Binary[116, 101, 115, 116], 2)
    assert_equal 2, map[Erlang::Binary["test"]]
  end

end
