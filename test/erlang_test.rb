# encoding: utf-8

require 'test_helper'

class ErlangTest < Minitest::Test

  def test_compare
    # number < atom < reference < fun < port < pid < tuple < map < nil < list < bitstring
    number = 0
    atom = Erlang::Atom[]
    reference = Erlang::Reference[:'nonode@nohost', 0, [1, 0, 0]]
    fun = example_function
    port = Erlang::Port[:'nonode@nohost', 100, 1]
    pid = Erlang::Pid[:"nonode@nohost", 38, 0, 0]
    tuple = Erlang::Tuple[]
    map = Erlang::Map[]
    enil = Erlang::Nil
    list = Erlang::List[0]
    bitstring = Erlang::Binary[]
    # number
    assert_equal 0, Erlang.compare(number, number)
    assert_equal (-1), Erlang.compare(number, atom)
    assert_equal (-1), Erlang.compare(number, reference)
    assert_equal (-1), Erlang.compare(number, fun)
    assert_equal (-1), Erlang.compare(number, port)
    assert_equal (-1), Erlang.compare(number, pid)
    assert_equal (-1), Erlang.compare(number, tuple)
    assert_equal (-1), Erlang.compare(number, map)
    assert_equal (-1), Erlang.compare(number, enil)
    assert_equal (-1), Erlang.compare(number, list)
    assert_equal (-1), Erlang.compare(number, bitstring)
    assert_equal 1, Erlang.compare(atom, number)
    assert_equal 1, Erlang.compare(reference, number)
    assert_equal 1, Erlang.compare(fun, number)
    assert_equal 1, Erlang.compare(port, number)
    assert_equal 1, Erlang.compare(pid, number)
    assert_equal 1, Erlang.compare(tuple, number)
    assert_equal 1, Erlang.compare(map, number)
    assert_equal 1, Erlang.compare(enil, number)
    assert_equal 1, Erlang.compare(list, number)
    assert_equal 1, Erlang.compare(bitstring, number)
    # atom
    assert_equal 1, Erlang.compare(atom, number)
    assert_equal 0, Erlang.compare(atom, atom)
    assert_equal (-1), Erlang.compare(atom, reference)
    assert_equal (-1), Erlang.compare(atom, fun)
    assert_equal (-1), Erlang.compare(atom, port)
    assert_equal (-1), Erlang.compare(atom, pid)
    assert_equal (-1), Erlang.compare(atom, tuple)
    assert_equal (-1), Erlang.compare(atom, map)
    assert_equal (-1), Erlang.compare(atom, enil)
    assert_equal (-1), Erlang.compare(atom, list)
    assert_equal (-1), Erlang.compare(atom, bitstring)
    assert_equal (-1), Erlang.compare(number, atom)
    assert_equal 1, Erlang.compare(reference, atom)
    assert_equal 1, Erlang.compare(fun, atom)
    assert_equal 1, Erlang.compare(port, atom)
    assert_equal 1, Erlang.compare(pid, atom)
    assert_equal 1, Erlang.compare(tuple, atom)
    assert_equal 1, Erlang.compare(map, atom)
    assert_equal 1, Erlang.compare(enil, atom)
    assert_equal 1, Erlang.compare(list, atom)
    assert_equal 1, Erlang.compare(bitstring, atom)
    # reference
    assert_equal 1, Erlang.compare(reference, number)
    assert_equal 1, Erlang.compare(reference, atom)
    assert_equal 0, Erlang.compare(reference, reference)
    assert_equal (-1), Erlang.compare(reference, fun)
    assert_equal (-1), Erlang.compare(reference, port)
    assert_equal (-1), Erlang.compare(reference, pid)
    assert_equal (-1), Erlang.compare(reference, tuple)
    assert_equal (-1), Erlang.compare(reference, map)
    assert_equal (-1), Erlang.compare(reference, enil)
    assert_equal (-1), Erlang.compare(reference, list)
    assert_equal (-1), Erlang.compare(reference, bitstring)
    assert_equal (-1), Erlang.compare(number, reference)
    assert_equal (-1), Erlang.compare(atom, reference)
    assert_equal 1, Erlang.compare(fun, reference)
    assert_equal 1, Erlang.compare(port, reference)
    assert_equal 1, Erlang.compare(pid, reference)
    assert_equal 1, Erlang.compare(tuple, reference)
    assert_equal 1, Erlang.compare(map, reference)
    assert_equal 1, Erlang.compare(enil, reference)
    assert_equal 1, Erlang.compare(list, reference)
    assert_equal 1, Erlang.compare(bitstring, reference)
    # fun
    assert_equal 1, Erlang.compare(fun, number)
    assert_equal 1, Erlang.compare(fun, atom)
    assert_equal 1, Erlang.compare(fun, reference)
    assert_equal 0, Erlang.compare(fun, fun)
    assert_equal (-1), Erlang.compare(fun, port)
    assert_equal (-1), Erlang.compare(fun, pid)
    assert_equal (-1), Erlang.compare(fun, tuple)
    assert_equal (-1), Erlang.compare(fun, map)
    assert_equal (-1), Erlang.compare(fun, enil)
    assert_equal (-1), Erlang.compare(fun, list)
    assert_equal (-1), Erlang.compare(fun, bitstring)
    assert_equal (-1), Erlang.compare(number, fun)
    assert_equal (-1), Erlang.compare(atom, fun)
    assert_equal (-1), Erlang.compare(reference, fun)
    assert_equal 1, Erlang.compare(port, fun)
    assert_equal 1, Erlang.compare(pid, fun)
    assert_equal 1, Erlang.compare(tuple, fun)
    assert_equal 1, Erlang.compare(map, fun)
    assert_equal 1, Erlang.compare(enil, fun)
    assert_equal 1, Erlang.compare(list, fun)
    assert_equal 1, Erlang.compare(bitstring, fun)
    # port
    assert_equal 1, Erlang.compare(port, number)
    assert_equal 1, Erlang.compare(port, atom)
    assert_equal 1, Erlang.compare(port, reference)
    assert_equal 1, Erlang.compare(port, fun)
    assert_equal 0, Erlang.compare(port, port)
    assert_equal (-1), Erlang.compare(port, pid)
    assert_equal (-1), Erlang.compare(port, tuple)
    assert_equal (-1), Erlang.compare(port, map)
    assert_equal (-1), Erlang.compare(port, enil)
    assert_equal (-1), Erlang.compare(port, list)
    assert_equal (-1), Erlang.compare(port, bitstring)
    assert_equal (-1), Erlang.compare(number, port)
    assert_equal (-1), Erlang.compare(atom, port)
    assert_equal (-1), Erlang.compare(reference, port)
    assert_equal (-1), Erlang.compare(fun, port)
    assert_equal 1, Erlang.compare(pid, port)
    assert_equal 1, Erlang.compare(tuple, port)
    assert_equal 1, Erlang.compare(map, port)
    assert_equal 1, Erlang.compare(enil, port)
    assert_equal 1, Erlang.compare(list, port)
    assert_equal 1, Erlang.compare(bitstring, port)
    # pid
    assert_equal 1, Erlang.compare(pid, number)
    assert_equal 1, Erlang.compare(pid, atom)
    assert_equal 1, Erlang.compare(pid, reference)
    assert_equal 1, Erlang.compare(pid, fun)
    assert_equal 1, Erlang.compare(pid, port)
    assert_equal 0, Erlang.compare(pid, pid)
    assert_equal (-1), Erlang.compare(pid, tuple)
    assert_equal (-1), Erlang.compare(pid, map)
    assert_equal (-1), Erlang.compare(pid, enil)
    assert_equal (-1), Erlang.compare(pid, list)
    assert_equal (-1), Erlang.compare(pid, bitstring)
    assert_equal (-1), Erlang.compare(number, pid)
    assert_equal (-1), Erlang.compare(atom, pid)
    assert_equal (-1), Erlang.compare(reference, pid)
    assert_equal (-1), Erlang.compare(fun, pid)
    assert_equal (-1), Erlang.compare(port, pid)
    assert_equal 1, Erlang.compare(tuple, pid)
    assert_equal 1, Erlang.compare(map, pid)
    assert_equal 1, Erlang.compare(enil, pid)
    assert_equal 1, Erlang.compare(list, pid)
    assert_equal 1, Erlang.compare(bitstring, pid)
    # tuple
    assert_equal 1, Erlang.compare(tuple, number)
    assert_equal 1, Erlang.compare(tuple, atom)
    assert_equal 1, Erlang.compare(tuple, reference)
    assert_equal 1, Erlang.compare(tuple, fun)
    assert_equal 1, Erlang.compare(tuple, port)
    assert_equal 1, Erlang.compare(tuple, pid)
    assert_equal 0, Erlang.compare(tuple, tuple)
    assert_equal (-1), Erlang.compare(tuple, map)
    assert_equal (-1), Erlang.compare(tuple, enil)
    assert_equal (-1), Erlang.compare(tuple, list)
    assert_equal (-1), Erlang.compare(tuple, bitstring)
    assert_equal (-1), Erlang.compare(number, tuple)
    assert_equal (-1), Erlang.compare(atom, tuple)
    assert_equal (-1), Erlang.compare(reference, tuple)
    assert_equal (-1), Erlang.compare(fun, tuple)
    assert_equal (-1), Erlang.compare(port, tuple)
    assert_equal (-1), Erlang.compare(pid, tuple)
    assert_equal 1, Erlang.compare(map, tuple)
    assert_equal 1, Erlang.compare(enil, tuple)
    assert_equal 1, Erlang.compare(list, tuple)
    assert_equal 1, Erlang.compare(bitstring, tuple)
    # map
    assert_equal 1, Erlang.compare(map, number)
    assert_equal 1, Erlang.compare(map, atom)
    assert_equal 1, Erlang.compare(map, reference)
    assert_equal 1, Erlang.compare(map, fun)
    assert_equal 1, Erlang.compare(map, port)
    assert_equal 1, Erlang.compare(map, pid)
    assert_equal 1, Erlang.compare(map, tuple)
    assert_equal 0, Erlang.compare(map, map)
    assert_equal (-1), Erlang.compare(map, enil)
    assert_equal (-1), Erlang.compare(map, list)
    assert_equal (-1), Erlang.compare(map, bitstring)
    assert_equal (-1), Erlang.compare(number, map)
    assert_equal (-1), Erlang.compare(atom, map)
    assert_equal (-1), Erlang.compare(reference, map)
    assert_equal (-1), Erlang.compare(fun, map)
    assert_equal (-1), Erlang.compare(port, map)
    assert_equal (-1), Erlang.compare(pid, map)
    assert_equal (-1), Erlang.compare(tuple, map)
    assert_equal 1, Erlang.compare(enil, map)
    assert_equal 1, Erlang.compare(list, map)
    assert_equal 1, Erlang.compare(bitstring, map)
    # nil
    assert_equal 1, Erlang.compare(enil, number)
    assert_equal 1, Erlang.compare(enil, atom)
    assert_equal 1, Erlang.compare(enil, reference)
    assert_equal 1, Erlang.compare(enil, fun)
    assert_equal 1, Erlang.compare(enil, port)
    assert_equal 1, Erlang.compare(enil, pid)
    assert_equal 1, Erlang.compare(enil, tuple)
    assert_equal 1, Erlang.compare(enil, map)
    assert_equal 0, Erlang.compare(enil, enil)
    assert_equal (-1), Erlang.compare(enil, list)
    assert_equal (-1), Erlang.compare(enil, bitstring)
    assert_equal (-1), Erlang.compare(number, enil)
    assert_equal (-1), Erlang.compare(atom, enil)
    assert_equal (-1), Erlang.compare(reference, enil)
    assert_equal (-1), Erlang.compare(fun, enil)
    assert_equal (-1), Erlang.compare(port, enil)
    assert_equal (-1), Erlang.compare(pid, enil)
    assert_equal (-1), Erlang.compare(tuple, enil)
    assert_equal (-1), Erlang.compare(map, enil)
    assert_equal 1, Erlang.compare(list, enil)
    assert_equal 1, Erlang.compare(bitstring, enil)
    # list
    assert_equal 1, Erlang.compare(list, number)
    assert_equal 1, Erlang.compare(list, atom)
    assert_equal 1, Erlang.compare(list, reference)
    assert_equal 1, Erlang.compare(list, fun)
    assert_equal 1, Erlang.compare(list, port)
    assert_equal 1, Erlang.compare(list, pid)
    assert_equal 1, Erlang.compare(list, tuple)
    assert_equal 1, Erlang.compare(list, map)
    assert_equal 1, Erlang.compare(list, enil)
    assert_equal 0, Erlang.compare(list, list)
    assert_equal (-1), Erlang.compare(list, bitstring)
    assert_equal (-1), Erlang.compare(number, list)
    assert_equal (-1), Erlang.compare(atom, list)
    assert_equal (-1), Erlang.compare(reference, list)
    assert_equal (-1), Erlang.compare(fun, list)
    assert_equal (-1), Erlang.compare(port, list)
    assert_equal (-1), Erlang.compare(pid, list)
    assert_equal (-1), Erlang.compare(tuple, list)
    assert_equal (-1), Erlang.compare(map, list)
    assert_equal (-1), Erlang.compare(enil, list)
    assert_equal 1, Erlang.compare(bitstring, list)
    # bitstring
    assert_equal 1, Erlang.compare(bitstring, number)
    assert_equal 1, Erlang.compare(bitstring, atom)
    assert_equal 1, Erlang.compare(bitstring, reference)
    assert_equal 1, Erlang.compare(bitstring, fun)
    assert_equal 1, Erlang.compare(bitstring, port)
    assert_equal 1, Erlang.compare(bitstring, pid)
    assert_equal 1, Erlang.compare(bitstring, tuple)
    assert_equal 1, Erlang.compare(bitstring, map)
    assert_equal 1, Erlang.compare(bitstring, enil)
    assert_equal 1, Erlang.compare(bitstring, list)
    assert_equal 0, Erlang.compare(bitstring, bitstring)
    assert_equal (-1), Erlang.compare(number, bitstring)
    assert_equal (-1), Erlang.compare(atom, bitstring)
    assert_equal (-1), Erlang.compare(reference, bitstring)
    assert_equal (-1), Erlang.compare(fun, bitstring)
    assert_equal (-1), Erlang.compare(port, bitstring)
    assert_equal (-1), Erlang.compare(pid, bitstring)
    assert_equal (-1), Erlang.compare(tuple, bitstring)
    assert_equal (-1), Erlang.compare(map, bitstring)
    assert_equal (-1), Erlang.compare(enil, bitstring)
    assert_equal (-1), Erlang.compare(list, bitstring)
    # other
    assert_raises(ArgumentError) { Erlang.compare(Object.new, Object.new) }
  end

  def test_from
    # number
    assert_equal 1, Erlang.from(1)
    assert_equal 1.0, Erlang.from(1.0)
    assert_equal BigDecimal(1), Erlang.from(BigDecimal(1))
    assert_equal Rational(1), Erlang.from(Rational(1))
    # atom
    assert_equal Erlang::Atom[], Erlang.from(:"")
    assert_equal Erlang::EmptyAtom, Erlang.from(Erlang::Atom[])
    assert_equal Erlang::Atom["test"], Erlang.from(:test)
    assert_equal Erlang::FalseAtom, Erlang.from(false)
    assert_equal Erlang::NilAtom, Erlang.from(nil)
    assert_equal Erlang::TrueAtom, Erlang.from(true)
    assert_equal Erlang::Atom["test"], Erlang.from(Erlang::Atom["test"])
    # reference
    assert_equal Erlang::Reference[:'nonode@nohost', 0, 1], Erlang.from(Erlang::Reference[:'nonode@nohost', 0, 1])
    assert_equal Erlang::Reference[:'nonode@nohost', 0, [1, 0, 0]], Erlang.from(Erlang::Reference[:'nonode@nohost', 0, [1, 0, 0]])
    # function
    assert_equal Erlang::Export[:erlang, :make_ref, 0], Erlang.from(Erlang::Export[:erlang, :make_ref, 0])
    assert_equal example_function, Erlang.from(example_function)
    # port
    assert_equal Erlang::Port[:'nonode@nohost', 100, 1], Erlang.from(Erlang::Port[:'nonode@nohost', 100, 1])
    # pid
    assert_equal Erlang::Pid[:"nonode@nohost", 38, 0, 0], Erlang.from(Erlang::Pid[:"nonode@nohost", 38, 0, 0])
    # tuple
    assert_equal Erlang::EmptyTuple, Erlang.from(Erlang::Tuple[])
    assert_equal Erlang::Tuple[1], Erlang.from(Erlang::Tuple[1])
    # map
    assert_equal Erlang::Map[], Erlang.from({})
    assert_equal Erlang::EmptyMap, Erlang.from(Erlang::Map[])
    assert_equal Erlang::Map[a: 1], Erlang.from(a: 1)
    # nil
    assert_equal Erlang::Nil, Erlang.from([])
    assert_equal Erlang::Nil, Erlang.from(Erlang::List[])
    assert_equal Erlang::Nil, Erlang.from(Erlang::Nil)
    assert_equal Erlang::Nil, Erlang.from(Erlang::String[])
    # list
    assert_equal Erlang::List[1], Erlang.from([1])
    assert_equal Erlang::List[1], Erlang.from(Erlang::List[1])
    assert_equal Erlang::List[1], Erlang.from(Erlang::String[1])
    assert_equal Erlang::String[1], Erlang.from(Erlang::String[1])
    # bitstring
    assert_equal Erlang::Binary[], Erlang.from(::String.new)
    assert_equal Erlang::EmptyBinary, Erlang.from(Erlang::Bitstring[])
    assert_equal Erlang::Binary["test"], Erlang.from("test")
    assert_equal Erlang::Binary[1], Erlang.from(Erlang::Binary[1])
    assert_equal Erlang::Bitstring[1], Erlang.from(Erlang::Bitstring[1])
    assert_equal Erlang::Bitstring[1, bits: 1], Erlang.from(Erlang::Bitstring[1, bits: 1])
    assert_equal Erlang::Binary[1], Erlang.from(Erlang::Bitstring[1, bits: 8])
    refute_equal Erlang::Binary[1], Erlang.from(Erlang::Bitstring[1, bits: 1])
    # other
    assert_raises(ArgumentError) { Erlang.from(Object.new) }
  end

  def test_is_any
    ## Assertions ##
    # is_atom
    badstring = Erlang::Terms.binary_encoding("\xCE")
    badsymbol = badstring.intern
    assert Erlang.is_any(nil)
    assert Erlang.is_any(:atom)
    assert Erlang.is_any(:Ω)
    assert Erlang.is_any(badsymbol)
    assert Erlang.is_any(Erlang::Atom["test"])
    assert Erlang.is_any(Erlang.from(:test))
    # is_binary
    assert Erlang.is_any('')
    assert Erlang.is_any(Erlang::Binary["test"])
    # is_bitstring
    assert Erlang.is_any(Erlang::Bitstring["test", bits: 7])
    # is_boolean
    assert Erlang.is_any(false)
    assert Erlang.is_any(true)
    # is_float
    assert Erlang.is_any(0.0)
    # is_function
    assert Erlang.is_any(example_function)
    assert Erlang.is_any(Erlang::Export[:erlang, :make_ref, 0])
    # is_integer
    assert Erlang.is_any(0)
    # is_list
    assert Erlang.is_any([])
    assert Erlang.is_any(Erlang::Nil)
    assert Erlang.is_any(Erlang::List[])
    assert Erlang.is_any(Erlang::String[])
    # is_map
    assert Erlang.is_any({})
    assert Erlang.is_any(Erlang::Map[])
    # is_number
    assert Erlang.is_any(BigDecimal(1))
    assert Erlang.is_any(Rational(1))
    # is_pid
    assert Erlang.is_any(Erlang::Pid[:"nonode@nohost", 38, 0, 0])
    # is_port
    assert Erlang.is_any(Erlang::Port[:'nonode@nohost', 100, 1])
    # is_reference
    assert Erlang.is_any(Erlang::Reference[:'nonode@nohost', 0, 1])
    assert Erlang.is_any(Erlang::Reference[:'nonode@nohost', 0, [1, 0, 0]])
    # is_tuple
    assert Erlang.is_any(Erlang::Tuple[])
    ## Refutations ##
    refute Erlang.is_any(Object.new)
  end

  def test_is_atom
    badstring = Erlang::Terms.binary_encoding("\xCE")
    badsymbol = badstring.intern
    assert Erlang.is_atom(true)
    assert Erlang.is_atom(false)
    assert Erlang.is_atom(nil)
    assert Erlang.is_atom(:true)
    assert Erlang.is_atom(:false)
    assert Erlang.is_atom(:nil)
    assert Erlang.is_atom(:test)
    assert Erlang.is_atom(:Ω)
    assert Erlang.is_atom(:"\xCE\xA9")
    assert Erlang.is_atom(badsymbol)
    assert Erlang.is_atom(:"")
    assert Erlang.is_atom(Erlang::Atom[true])
    assert Erlang.is_atom(Erlang::Atom[false])
    assert Erlang.is_atom(Erlang::Atom[nil])
    assert Erlang.is_atom(Erlang::Atom[:true])
    assert Erlang.is_atom(Erlang::Atom[:false])
    assert Erlang.is_atom(Erlang::Atom[:nil])
    assert Erlang.is_atom(Erlang::Atom[:test])
    assert Erlang.is_atom(Erlang::Atom[:Ω])
    assert Erlang.is_atom(Erlang::Atom[:"\xCE\xA9"])
    assert Erlang.is_atom(Erlang::Atom[badsymbol])
    assert Erlang.is_atom(Erlang::Atom["true"])
    assert Erlang.is_atom(Erlang::Atom["false"])
    assert Erlang.is_atom(Erlang::Atom["nil"])
    assert Erlang.is_atom(Erlang::Atom["test"])
    assert Erlang.is_atom(Erlang::Atom["Ω"])
    assert Erlang.is_atom(Erlang::Atom["\xCE\xA9"])
    assert Erlang.is_atom(Erlang::Atom[badstring])
    assert Erlang.is_atom(Erlang::Atom[:""])
    assert Erlang.is_atom(Erlang::Atom[""])
    assert Erlang.is_atom(Erlang::Atom[])
    assert Erlang.is_atom(Erlang::Atom.empty)
    assert Erlang.is_atom(Erlang::Atom.false)
    assert Erlang.is_atom(Erlang::Atom.nil)
    assert Erlang.is_atom(Erlang::Atom.true)
    assert Erlang.is_atom(Erlang::EmptyAtom)
    assert Erlang.is_atom(Erlang::FalseAtom)
    assert Erlang.is_atom(Erlang::NilAtom)
    assert Erlang.is_atom(Erlang::TrueAtom)
    assert Erlang.is_atom(Erlang.from(true))
    assert Erlang.is_atom(Erlang.from(nil))
    assert Erlang.is_atom(Erlang.from(false))
    assert Erlang.is_atom(Erlang.from(:true))
    assert Erlang.is_atom(Erlang.from(:nil))
    assert Erlang.is_atom(Erlang.from(:false))
    assert Erlang.is_atom(Erlang.from(Erlang::Atom[:test]))
    refute Erlang.is_atom(0)
  end

  def test_is_binary
    assert Erlang.is_binary(::String.new)
    assert Erlang.is_binary('')
    assert Erlang.is_binary('a')
    assert Erlang.is_binary('Ω')
    assert Erlang.is_binary(Erlang::Binary[])
    assert Erlang.is_binary(Erlang::Bitstring[])
    assert Erlang.is_binary(Erlang::Binary['a'])
    assert Erlang.is_binary(Erlang::Binary['a', [Erlang::Binary['b'], :c, Erlang::List["d"]]])
    assert Erlang.is_binary(Erlang::Bitstring['a'])
    refute Erlang.is_binary(Erlang::Bitstring['a', bits: 7])
    refute Erlang.is_binary(nil)
  end

  def test_is_bitstring
    assert Erlang.is_bitstring(::String.new)
    assert Erlang.is_bitstring('')
    assert Erlang.is_bitstring('a')
    assert Erlang.is_bitstring('Ω')
    assert Erlang.is_bitstring(Erlang::Binary[])
    assert Erlang.is_bitstring(Erlang::Bitstring[])
    assert Erlang.is_bitstring(Erlang::Binary['a'])
    assert Erlang.is_bitstring(Erlang::Bitstring['a'])
    assert Erlang.is_bitstring(Erlang::Bitstring['a', bits: 7])
    refute Erlang.is_bitstring(nil)
  end

  def test_is_boolean
    assert Erlang.is_boolean(true)
    assert Erlang.is_boolean(false)
    assert Erlang.is_boolean(:true)
    assert Erlang.is_boolean(:false)
    assert Erlang.is_boolean(Erlang::Atom[true])
    assert Erlang.is_boolean(Erlang::Atom[false])
    assert Erlang.is_boolean(Erlang::Atom[:true])
    assert Erlang.is_boolean(Erlang::Atom[:false])
    assert Erlang.is_boolean(Erlang::Atom["true"])
    assert Erlang.is_boolean(Erlang::Atom["false"])
    assert Erlang.is_boolean(Erlang.from(true))
    assert Erlang.is_boolean(Erlang.from(false))
    assert Erlang.is_boolean(Erlang.from(:true))
    assert Erlang.is_boolean(Erlang.from(:false))
    refute Erlang.is_boolean(Erlang::Atom[nil])
    refute Erlang.is_boolean("true")
    refute Erlang.is_boolean("false")
    refute Erlang.is_boolean(Erlang.from(Erlang::Atom[:test]))
    refute Erlang.is_boolean(nil)
  end

  def test_is_float
    assert Erlang.is_float(Float(0))
    assert Erlang.is_float(0.0)
    assert Erlang.is_float(1.0)
    assert Erlang.is_float(-1.0)
    assert Erlang.is_float(1.0 / 2.0)
    assert Erlang.is_float(BigDecimal('1'))
    assert Erlang.is_float(Rational(1, 2))
    assert Erlang.is_float(Erlang.from(1.0))
    assert Erlang.is_float(Erlang.from(BigDecimal('1')))
    assert Erlang.is_float(Erlang.from(Rational(1, 2)))
    refute Erlang.is_float(nil)
  end

  def test_is_function
    fun = example_function
    assert Erlang.is_function(Erlang::Export[:erlang, :make_ref, 0])
    assert Erlang.is_function(Erlang::Export[:erlang, :make_ref, 0], 0)
    refute Erlang.is_function(Erlang::Export[:erlang, :make_ref, 0], 1)
    assert Erlang.is_function(fun)
    assert Erlang.is_function(fun, 0)
    refute Erlang.is_function(fun, 1)
    refute Erlang.is_function(nil)
  end

  def test_is_integer
    assert Erlang.is_integer(0)
    assert Erlang.is_integer(1)
    assert Erlang.is_integer(-1)
    assert Erlang.is_integer(1 / 2)
    assert Erlang.is_integer(Integer(1))
    assert Erlang.is_integer(1 << 1024)
    assert Erlang.is_integer(Erlang.from(1))
    assert Erlang.is_integer(Erlang.from(Integer(1)))
    assert Erlang.is_integer(Erlang.from(1 << 1024))
    refute Erlang.is_integer(nil)
  end

  def test_is_list
    assert Erlang.is_list([])
    assert Erlang.is_list([1, 2])
    assert Erlang.is_list(Erlang::List[])
    assert Erlang.is_list(Erlang::List.empty)
    assert Erlang.is_list(Erlang::Nil)
    assert Erlang.is_list(Erlang::List[1, 2])
    assert Erlang.is_list(Erlang.from(Erlang::List[1, 2]))
    assert Erlang.is_list(Erlang::List[1] + 2)
    assert Erlang.is_list(Erlang::String[])
    assert Erlang.is_list(Erlang::EmptyString)
    assert Erlang.is_list(Erlang::String["test"])
    refute Erlang.is_list(nil)
  end

  def test_is_map
    assert Erlang.is_map({})
    assert Erlang.is_map({a: 1})
    assert Erlang.is_map(Erlang::Map[a: 1])
    assert Erlang.is_map(Erlang::Map[:a, 1])
    assert Erlang.is_map(Erlang.from(a: 1))
    assert Erlang.is_map(Erlang.from(Erlang::Map[a: 1]))
    refute Erlang.is_map(nil)
  end

  def test_is_number
    assert Erlang.is_number(0.0)
    assert Erlang.is_number(1.0)
    assert Erlang.is_number(-1.0)
    assert Erlang.is_number(1.0 / 2.0)
    assert Erlang.is_number(BigDecimal('1'))
    assert Erlang.is_number(Rational(1, 2))
    assert Erlang.is_number(0)
    assert Erlang.is_number(1)
    assert Erlang.is_number(-1)
    assert Erlang.is_number(1 / 2)
    assert Erlang.is_number(Integer(1))
    assert Erlang.is_number(1 << 1024)
    assert Erlang.is_number(Erlang.from(1.0))
    assert Erlang.is_number(Erlang.from(BigDecimal('1')))
    assert Erlang.is_number(Erlang.from(Rational(1, 2)))
    assert Erlang.is_number(Erlang.from(1))
    assert Erlang.is_number(Erlang.from(Integer(1)))
    assert Erlang.is_number(Erlang.from(1 << 1024))
    refute Erlang.is_number(nil)
  end

  def test_is_pid
    assert Erlang.is_pid(Erlang::Pid[:"nonode@nohost", 38, 0, 0])
    assert Erlang.is_pid(Erlang.from(Erlang::Pid[:"nonode@nohost", 38, 0, 0]))
    refute Erlang.is_pid(nil)
  end

  def test_is_port
    assert Erlang.is_port(Erlang::Port[:'nonode@nohost', 100, 1])
    assert Erlang.is_port(Erlang.from(Erlang::Port[:'nonode@nohost', 100, 1]))
    refute Erlang.is_port(nil)
  end

  def test_is_reference
    assert Erlang.is_reference(Erlang::Reference[:'nonode@nohost', 0, 1])
    assert Erlang.is_reference(Erlang::Reference[:'nonode@nohost', 0, [1, 0, 0]])
    assert Erlang.is_reference(Erlang.from(Erlang::Reference[:'nonode@nohost', 0, 1]))
    assert Erlang.is_reference(Erlang.from(Erlang::Reference[:'nonode@nohost', 0, [1, 0, 0]]))
    refute Erlang.is_reference(nil)
  end

  def test_is_tuple
    assert Erlang.is_tuple(Erlang::Tuple[])
    assert Erlang.is_tuple(Erlang::Tuple.empty)
    assert Erlang.is_tuple(Erlang::EmptyTuple)
    assert Erlang.is_tuple(Erlang::Tuple[1, 2])
    assert Erlang.is_tuple(Erlang.from(Erlang::Tuple[1, 2]))
    refute Erlang.is_tuple(nil)
  end

  def test_type
    assert_equal :atom, Erlang.type(:"")
    assert_equal :atom, Erlang.type(:test)
    assert_equal :atom, Erlang.type(Erlang::Atom["test"])
    assert_equal :atom, Erlang.type(true)
    assert_equal :atom, Erlang.type(false)
    assert_equal :atom, Erlang.type(nil)
    assert_equal :bitstring, Erlang.type(::String.new)
    assert_equal :bitstring, Erlang.type('')
    assert_equal :bitstring, Erlang.type("test")
    assert_equal :bitstring, Erlang.type(Erlang::Binary[])
    assert_equal :bitstring, Erlang.type(Erlang::Binary["test"])
    assert_equal :bitstring, Erlang.type(Erlang::Bitstring[])
    assert_equal :bitstring, Erlang.type(Erlang::Bitstring["test", bits: 7])
    assert_equal :fun, Erlang.type(Erlang::Export[:erlang, :make_ref, 0])
    assert_equal :fun, Erlang.type(example_function)
    assert_equal :list, Erlang.type([1])
    assert_equal :list, Erlang.type(Erlang::List[1])
    assert_equal :list, Erlang.type(Erlang::String["test"])
    assert_equal :map, Erlang.type({})
    assert_equal :map, Erlang.type(Erlang::Map[])
    assert_equal :nil, Erlang.type([])
    assert_equal :nil, Erlang.type(Erlang::List[])
    assert_equal :nil, Erlang.type(Erlang::Nil)
    assert_equal :nil, Erlang.type(Erlang::String[])
    assert_equal :number, Erlang.type(0)
    assert_equal :number, Erlang.type(1.0)
    assert_equal :number, Erlang.type(BigDecimal('1'))
    assert_equal :number, Erlang.type(Rational(1, 2))
    assert_equal :pid, Erlang.type(Erlang::Pid[:"nonode@nohost", 38, 0, 0])
    assert_equal :port, Erlang.type(Erlang::Port[:'nonode@nohost', 100, 1])
    assert_equal :reference, Erlang.type(Erlang::Reference[:'nonode@nohost', 0, 1])
    assert_equal :reference, Erlang.type(Erlang::Reference[:'nonode@nohost', 0, [1, 0, 0]])
    assert_equal :tuple, Erlang.type(Erlang::Tuple[])
    assert_raises(NotImplementedError) { Erlang.type(Object.new) }
  end

private
  def example_function
    return Erlang::Function[
      arity: 0,
      uniq: "c>yRz_\xF6\xED?Hv(\x04\x19\x102",
      index: 20,
      mod: :erl_eval,
      old_index: 20,
      old_uniq: 52032458,
      pid: Erlang::Pid[:"nonode@nohost", 79, 0, 0],
      free_vars: Erlang::List[
        Erlang::Tuple[
          Erlang::Nil,
          :none,
          :none,
          Erlang::List[
            Erlang::Tuple[
              :clause,
              27,
              Erlang::Nil,
              Erlang::Nil,
              Erlang::List[Erlang::Tuple[:atom, 0, :ok]]
            ]
          ]
        ]
      ]
    ]
  end

end
