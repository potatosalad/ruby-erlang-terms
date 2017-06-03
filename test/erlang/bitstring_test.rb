# encoding: utf-8

require 'test_helper'

class Erlang::BitstringTest < Minitest::Test

  def test_create
    lhs = Erlang::Bitstring[255, bits: 7]
    assert_equal 7, lhs.bits
    assert_equal lhs, Erlang::Bitstring[255, bits: 7]
    refute_equal lhs, Erlang::Bitstring[0, bits: 7]
    refute_equal lhs, Erlang::Bitstring[255, bits: 6]
    refute_equal lhs, Erlang::Bitstring[255, bits: 8]
    lhs = Erlang::Bitstring["\x00\xCE"]
    assert_equal lhs, Erlang::Bitstring[0, 206]
    assert_equal Erlang::Binary.empty, Erlang::Bitstring.empty
    assert_raises(ArgumentError) { Erlang::Bitstring[Object.new] }
  end

  def test_compare
    lhs = Erlang::Bitstring[1, 6, bits: 3]
    rhs = Erlang::Bitstring[1, 6, bits: 3]
    assert_equal 0, Erlang::Bitstring.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::Bitstring[1, 6, bits: 3]
    rhs = Erlang::Bitstring[1, 7, bits: 3]
    assert_equal -1, Erlang::Bitstring.compare(lhs, rhs)
    assert_equal 1, Erlang::Bitstring.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
    lhs = Erlang::Bitstring[1, 6, bits: 4]
    rhs = Erlang::Bitstring[1, 6, bits: 3]
    assert_equal -1, Erlang::Bitstring.compare(lhs, rhs)
    assert_equal 1, Erlang::Bitstring.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_at
    b = Erlang::Bitstring[1, 6, bits: 3]
    assert_raises(NotImplementedError) { b.at(1) }
  end

  def test_bitsize
    b = Erlang::Bitstring[1, 6, bits: 3]
    assert_equal 11, b.bitsize
  end

  def test_bitslice
    b  = Erlang::Bitstring[117, bits: 7]
    b3 = Erlang::Bitstring[7, bits: 3]
    b4 = Erlang::Bitstring[5, bits: 4]
    assert_equal b3, b.bitslice(0, 3)
    assert_equal b4, b.bitslice(3, 4)
    assert_equal b3, b.bitslice(0...3)
    assert_equal b4, b.bitslice(3...7)
    assert_equal 0, Erlang::Bitstring[1, bits: 2].bitslice(0)
    assert_equal 1, Erlang::Bitstring[1, bits: 2].bitslice(1)
    assert_equal 1, Erlang::Bitstring[1, bits: 2].bitslice(-1)
    assert_nil Erlang::Bitstring[1, bits: 2].bitslice(2)
    b = Erlang::Bitstring[1, 1, bits: 1]
    assert_equal Erlang::Binary[1], b.bitslice(0...8)
  end

  def test_bytesize
    b = Erlang::Bitstring[1, 6, bits: 3]
    assert_equal 2, b.bytesize
  end

  def test_concat
    b  = Erlang::Bitstring[117, bits: 7]
    b3 = Erlang::Bitstring[7, bits: 3]
    b4 = Erlang::Bitstring[5, bits: 4]
    b1 = Erlang::Bitstring[0, bits: 1]
    x  = Erlang::Binary["x"]
    bx = Erlang::Binary["\xEF\n"]
    assert_equal b, Erlang::Bitstring.concat(b3, b4)
    assert_equal b, (b3 + b4)
    assert_equal bx, (b3 + x + b4 + b1)
    assert_equal Erlang::Bitstring[234, 2, 2, bits: 7], b.concat(1, 2)
    assert_equal Erlang::Binary[1, 2], Erlang::Bitstring.new("\x01", 8).concat(2)
  end

  def test_property_of_concat
    property_of {
      random_erlang_bitstring
    }.check { |bitstring|
      number = SecureRandom.random_number((bitstring.bitsize == 0) ? 1 : bitstring.bitsize) + 1
      assert_equal bitstring, Erlang::Bitstring.concat(*bitstring.each_bitslice(number))
    }
  end

  def test_copy
    b = Erlang::Bitstring[1, 6, bits: 3]
    assert_raises(NotImplementedError) { b.copy(2) }
  end

  def test_decode_unsigned
    b = Erlang::Bitstring[1, 6, bits: 3]
    assert_raises(NotImplementedError) { b.decode_unsigned() }
  end

  def test_each_bit
    bitstring = Erlang::Bitstring[127, 0, 254, bits: 4]
    bits = [0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,0]
    enum = bitstring.each_bit
    assert enum.is_a?(Enumerator)
    assert_equal bits, enum.to_a
    array = []
    bitstring.each_bit { |bit| array.push(bit) }
    assert_equal bits, array
  end

  def test_each_bitslice
    b  = Erlang::Bitstring[117, 254, bits: 3]
    b8 = [
      Erlang::Binary[117],
      Erlang::Bitstring[6, bits: 3]
    ]
    b7 = [
      Erlang::Bitstring[58, bits: 7],
      Erlang::Bitstring[14, bits: 4]
    ]
    b6 = [
      Erlang::Bitstring[29, bits: 6],
      Erlang::Bitstring[14, bits: 5]
    ]
    b5 = [
      Erlang::Bitstring[14, bits: 5],
      Erlang::Bitstring[23, bits: 5],
      Erlang::Bitstring[0, bits: 1]
    ]
    b4 = [
      Erlang::Bitstring[7, bits: 4],
      Erlang::Bitstring[5, bits: 4],
      Erlang::Bitstring[6, bits: 3]
    ]
    b3 = [
      Erlang::Bitstring[3, bits: 3],
      Erlang::Bitstring[5, bits: 3],
      Erlang::Bitstring[3, bits: 3],
      Erlang::Bitstring[2, bits: 2]
    ]
    b2 = [
      Erlang::Bitstring[1, bits: 2],
      Erlang::Bitstring[3, bits: 2],
      Erlang::Bitstring[1, bits: 2],
      Erlang::Bitstring[1, bits: 2],
      Erlang::Bitstring[3, bits: 2],
      Erlang::Bitstring[0, bits: 1]
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
      Erlang::Bitstring[0, bits: 1]
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
    b = Erlang::Bitstring[127, 0, 254, bits: 3]
    assert_raises(NotImplementedError) { b.each_byte() }
  end

  def test_empty?
    assert Erlang::Bitstring[].empty?
    assert Erlang::Bitstring["", bits: 1].empty?
    refute Erlang::Bitstring[255, bits: 1].empty?
  end

  def test_first
    assert_raises(NotImplementedError) { Erlang::Bitstring[255, bits: 1].first }
  end

  def test_last
    assert_raises(NotImplementedError) { Erlang::Bitstring[255, bits: 1].last }
  end

  def test_part
    assert_raises(NotImplementedError) { Erlang::Bitstring[255, bits: 1].part(0, 1) }
  end

  def test_erlang_inspect
    assert_equal "<<7:3>>", Erlang::Bitstring[255, bits: 3].erlang_inspect
    assert_equal "<<206,169,117:7>>", Erlang::Bitstring["Ω", 117, bits: 7].erlang_inspect
    assert_equal "<<1>>", Erlang::Bitstring.new("\x01", 8).erlang_inspect
  end

  def test_inspect
    assert_equal "\"test\"", Erlang::Bitstring["test"].inspect
    assert_equal "\"Ω\"", Erlang::Bitstring["Ω"].inspect
    assert_equal "Erlang::Bitstring[7, bits: 3]", Erlang::Bitstring[255, bits: 3].inspect
    assert_equal "Erlang::Bitstring[206, 169, 117, bits: 7]", Erlang::Bitstring["Ω", 117, bits: 7].inspect
  end

  def test_property_of_inspect
    property_of {
      random_erlang_bitstring
    }.check { |bitstring|
      assert_equal bitstring, eval(bitstring.inspect)
    }
  end

  def test_to_binary
    assert_equal Erlang::Binary[15], Erlang::Bitstring[255, bits: 4].to_binary
    assert_equal Erlang::Bitstring[255, bits: 3], Erlang::Bitstring[255, bits: 4].to_binary.to_bitstring(3)
  end

  def test_to_s
    assert_equal "\x0F", Erlang::Bitstring[255, bits: 4].to_s
  end

  def test_marshal
    lhs = Erlang::Bitstring[255, bits: 3]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::Bitstring["Ω", 117, bits: 7]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::Bitstring[255, bits: 4], 1)
    map = map.put(Erlang::Bitstring[255, bits: 4], 2)
    assert_equal 2, map[Erlang::Bitstring[255, bits: 4]]
  end

end
