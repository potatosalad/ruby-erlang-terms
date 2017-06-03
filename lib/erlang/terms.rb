require 'erlang/terms/version'

require 'bigdecimal'
require 'rational'

require 'erlang/undefined'

module Erlang
  # @private
  module Terms
    PRINTABLE       = /\A[[:print:]]+\z/.freeze
    BINARY_ENCODING = Encoding.find('binary')
    UTF8_ENCODING   = Encoding.find('utf-8')
    UINT8_SPLAT     = 'C*'.freeze
    TERM_ORDER      = {
      number:     0,
      atom:       1,
      reference:  2,
      fun:        3,
      port:       4,
      pid:        5,
      tuple:      6,
      map:        7,
      nil:        8,
      list:       9,
      bitstring: 10
    }.freeze

    def self.binary_encoding(string)
      string = string.dup if string.frozen?
      string = string.force_encoding(BINARY_ENCODING)
      return string
    end

    def self.printable?(string)
      return !!(PRINTABLE =~ string)
    end

    def self.utf8_encoding(string)
      string = string.dup if string.frozen?
      begin
        string = string.encode(UTF8_ENCODING)
      rescue EncodingError
        string = string.force_encoding(UTF8_ENCODING)
      end
      if string.valid_encoding?
        return true, string
      else
        string = binary_encoding(string)
        return false, string
      end
    end
  end

  def self.compare(a, b)
    a = Erlang.from(a)
    b = Erlang.from(b)
    t = type(a)
    c = Erlang::Terms::TERM_ORDER[t] <=> Erlang::Terms::TERM_ORDER[type(b)]
    return c if c != 0
    case t
    when :atom
      return Erlang::Atom.compare(a, b)
    when :bitstring
      return Erlang::Bitstring.compare(a, b)
    when :fun
      return Erlang::Function.compare(a, b)
    when :list
      return Erlang::List.compare(a, b)
    when :map
      return Erlang::Map.compare(a, b)
    when :nil
      return 0
    when :number
      if is_float(a) or is_float(b)
        af = a
        if not is_float(a)
          begin
            af = Erlang::Float[a]
          rescue ArgumentError
            af = a
          end
        end
        bf = b
        if not is_float(b)
          begin
            bf = Erlang::Float[b]
          rescue ArgumentError
            bf = b
          end
        end
        return Erlang::Float.compare(af, bf) if af.kind_of?(Erlang::Float) and bf.kind_of?(Erlang::Float)
        return af.data <=> bf if af.kind_of?(Erlang::Float) and not bf.kind_of?(Erlang::Float)
        afbfcmp = bf.data <=> af
        return -afbfcmp
      end
      return a <=> b
    when :pid
      return Erlang::Pid.compare(a, b)
    when :port
      return Erlang::Port.compare(a, b)
    when :reference
      return Erlang::Reference.compare(a, b)
    when :tuple
      return Erlang::Tuple.compare(a, b)
    else
      raise NotImplementedError
    end
  end

  def self.from(term)
    return term.to_erlang if term.respond_to?(:to_erlang)
    # integer
    return term if is_integer(term)
    # float
    return term if term.kind_of?(Erlang::Float)
    return Erlang::Float[term] if is_float(term)
    # atom
    return term if term.kind_of?(Erlang::Atom)
    return Erlang::Atom[term] if term.kind_of?(::Symbol)
    return Erlang::Atom[term] if term.kind_of?(::FalseClass)
    return Erlang::Atom[term] if term.kind_of?(::NilClass)
    return Erlang::Atom[term] if term.kind_of?(::TrueClass)
    # reference, function, port, pid, and tuple
    return term if is_reference(term)
    return term if is_function(term)
    return term if is_port(term)
    return term if is_pid(term)
    return term if is_tuple(term)
    # map
    return term if term.kind_of?(Erlang::Map)
    return Erlang::Map[term] if term.kind_of?(::Hash)
    # nil
    return term if term.equal?(Erlang::Nil)
    return Erlang::Nil if is_list(term) and term.empty?
    # list
    return term if term.kind_of?(Erlang::List)
    return term if term.kind_of?(Erlang::String)
    return Erlang::List.from_enum(term) if term.kind_of?(::Array)
    # bitstring
    return term if term.kind_of?(Erlang::Binary)
    return term if term.kind_of?(Erlang::Bitstring)
    return Erlang::Binary[term] if term.kind_of?(::String)
    raise ArgumentError, "unable to convert ruby object of class #{term.class} to erlang term"
  end

  def self.inspect(term = Erlang::Undefined, raw: false)
    return super() if Erlang::Undefined.equal?(term)
    term = from(term)
    return term.erlang_inspect(raw) if term.respond_to?(:erlang_inspect)
    return term.inspect if is_any(term)
    raise NotImplementedError
  end

  def self.iolist_to_binary(iolist)
    return iolist if is_binary(iolist)
    return Erlang::Binary.new(iolist) if iolist.is_a?(::String)
    return Erlang::Binary.new(iolist.to_s) if iolist.is_a?(::Symbol)
    if is_list(iolist)
      return Erlang::Binary.new(iolist.flatten.map do |element|
        data = nil
        if element.is_a?(::Integer) and element <= 255 and element >= -256
          element = element + 256 if element < 0
          data = element.chr
        elsif element.is_a?(::String)
          data = element
        elsif is_binary(element)
          data = element.data
        elsif element.is_a?(::Symbol)
          data = element.to_s
        elsif is_list(element)
          data = iolist_to_binary(element).data
        else
          raise ArgumentError, "unknown element in iolist: #{element.inspect}"
        end
        next Erlang::Terms.binary_encoding(data)
      end.join)
    else
      raise ArgumentError, "unrecognized iolist: #{iolist.inspect}"
    end
  end

  def self.is_any(term)
    return true if is_atom(term)
    return true if is_bitstring(term)
    return true if is_boolean(term)
    return true if is_float(term)
    return true if is_function(term)
    return true if is_integer(term)
    return true if is_list(term)
    return true if is_map(term)
    return true if is_number(term)
    return true if is_pid(term)
    return true if is_port(term)
    return true if is_reference(term)
    return true if is_tuple(term)
    return false
  end

  def self.is_atom(term)
    return true if term.kind_of?(::Symbol)
    return true if term.kind_of?(::FalseClass)
    return true if term.kind_of?(::NilClass)
    return true if term.kind_of?(::TrueClass)
    return true if term.kind_of?(Erlang::Atom)
    return false
  end

  def self.is_binary(term)
    return true if term.kind_of?(::String)
    return true if term.kind_of?(Erlang::Binary)
    return false
  end

  def self.is_bitstring(term)
    return true if is_binary(term)
    return true if term.kind_of?(Erlang::Bitstring)
    return false
  end

  def self.is_boolean(term)
    return true if term.kind_of?(::FalseClass)
    return true if term.kind_of?(::TrueClass)
    return true if term == :true
    return true if term == :false
    return false
  end

  def self.is_float(term)
    return true if term.kind_of?(::BigDecimal)
    return true if term.kind_of?(::Float)
    return true if term.kind_of?(::Rational)
    return true if term.kind_of?(Erlang::Float)
    return false
  end

  def self.is_function(term, arity = nil)
    if arity == nil
      return true if term.kind_of?(Erlang::Export)
      return true if term.kind_of?(Erlang::Function)
    else
      return true if is_function(term) and term.arity == arity
    end
    return false
  end

  def self.is_integer(term)
    return true if term.kind_of?(::Integer)
    return false
  end

  def self.is_list(term)
    return true if term.kind_of?(Erlang::List)
    return true if term.kind_of?(Erlang::String)
    return true if term.kind_of?(::Array)
    return true if term.equal?(Erlang::Nil)
    return false
  end

  def self.is_map(term)
    return true if term.kind_of?(Erlang::Map)
    return true if term.kind_of?(::Hash)
    return false
  end

  def self.is_number(term)
    return true if is_float(term) or is_integer(term)
    return false
  end

  def self.is_pid(term)
    return true if term.kind_of?(Erlang::Pid)
    return false
  end

  def self.is_port(term)
    return true if term.kind_of?(Erlang::Port)
    return false
  end

  def self.is_reference(term)
    return true if term.kind_of?(Erlang::Reference)
    return false
  end

  def self.is_tuple(term)
    return true if term.kind_of?(Erlang::Tuple)
    return false
  end

  def self.type(term)
    return :atom if is_atom(term)
    return :bitstring if is_bitstring(term)
    return :fun if is_function(term)
    return :list if is_list(term) and not term.empty?
    return :map if is_map(term)
    return :nil if is_list(term) and term.empty?
    return :number if is_number(term)
    return :pid if is_pid(term)
    return :port if is_port(term)
    return :reference if is_reference(term)
    return :tuple if is_tuple(term)
    raise NotImplementedError
  end

end

require 'erlang/associable'
require 'erlang/enumerable'
require 'erlang/immutable'

require 'erlang/error'
require 'erlang/list'
require 'erlang/term'
require 'erlang/trie'

require 'erlang/atom'
require 'erlang/binary'
require 'erlang/bitstring'
require 'erlang/compressed'
require 'erlang/cons'
require 'erlang/export'
require 'erlang/float'
require 'erlang/function'
require 'erlang/map'
require 'erlang/nil'
require 'erlang/pid'
require 'erlang/port'
require 'erlang/reference'
require 'erlang/string'
require 'erlang/tuple'
