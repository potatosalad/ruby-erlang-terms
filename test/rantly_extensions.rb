require 'rantly/minitest_extensions'
require 'rantly/shrinks'
require 'securerandom'

class Rantly

  PRINTABLE     = /\A[[:print:]]+\z/.freeze
  UTF8_ENCODING = Encoding.find('utf-8')
  # ERLANG_ETF_SMALL_BIG_MIN = (-1 << (255 * 8)) + 1
  # ERLANG_ETF_SMALL_BIG_MAX = (+1 << (255 * 8)) - 1
  # ERLANG_ETF_LARGE_BIG_MIN = ERLANG_ETF_SMALL_BIG_MIN * 2
  # ERLANG_ETF_LARGE_BIG_MAX = ERLANG_ETF_SMALL_BIG_MAX * 2

  def erlang_atom(size = self.size, printable: false, utf8: false)
    return Erlang::Atom[(printable) ? random_printable_bytes(size) : random_bytes(size), utf8: utf8]
  end

  def erlang_binary(size = self.size, printable: false, multiplier: 8)
    allow_zero = !!(SecureRandom.random_number(3) == 0)
    bytesize = nil
    while bytesize.nil? or (not allow_zero and bytesize == 0)
      bytesize = SecureRandom.random_number(size) * (SecureRandom.random_number(multiplier) + 1)
    end
    if bytesize == 0
      return Erlang::Binary[]
    else
      return Erlang::Binary[(printable) ? random_printable_bytes(bytesize) : random_bytes(bytesize)]
    end
  end

  def erlang_bitstring(size = self.size, multiplier: 8)
    allow_zero = !!(SecureRandom.random_number(3) == 0)
    bytesize = nil
    while bytesize.nil? or (not allow_zero and bytesize == 0)
      bytesize = SecureRandom.random_number(size) * (SecureRandom.random_number(multiplier) + 1)
    end
    bits = SecureRandom.random_number(8) + 1
    if bytesize == 0
      return Erlang::Bitstring[]
    else
      return Erlang::Bitstring[random_bytes(bytesize), bits: bits]
    end
  end
  alias :random_erlang_bitstring :erlang_bitstring

  def erlang_export(size = self.size)
    return Erlang::Export[random_erlang_atom(size), random_erlang_atom(size), non_negative_integer(255)]
  end
  alias :random_erlang_export :erlang_export

  def erlang_float
    float_string = nil
    float_object = nil
    while float_string.nil? or float_object.to_s.include?("Infinity")
      e = range(-323, 308)
      sign = (range(0, 1) == 0) ? '' : '-'
      integer = range(0, 9)
      fractional = Array.new(20); 20.times { |i| fractional[i] = range(0, 9) }
      float_string = "#{sign}#{integer}.#{fractional.join}e#{(e >= 0) ? '+' : ''}#{e}"
      float_object = ::BigDecimal.new(::BigDecimal.new(float_string).to_s).to_f
    end
    return Erlang::Float[float_string, old: true]
  end

  def erlang_integer
    return integer
  end
  alias :random_erlang_integer :erlang_integer

  def erlang_list(size = self.size, depth: 0, &block)
    length = size
    elements = if block_given?
      length.times.map(&block)
    else
      length.times.map { random_erlang_term(size / 2, depth: depth - 1) }
    end
    return Erlang::List[*(elements.map { |element| Erlang.from(element) })]
  end

  def erlang_list_improper(size = self.size, depth: 0, tail: nil, &block)
    length = size
    elements = if block_given?
      length.times.map(&block)
    else
      length.times.map { random_erlang_term(size / 2, depth: depth - 1) }
    end
    if tail.nil?
      tail = random_erlang_term(size / 2, depth: depth - 1)
    elsif tail.is_a?(Proc)
      tail = instance_exec(&tail)
    end
    while Erlang.is_list(tail) and (not tail.respond_to?(:improper?) or not tail.improper?)
      tail = random_erlang_term(size / 2, depth: depth - 1)
    end
    term = Erlang::List[*(elements.map { |element| Erlang.from(element) })] + Erlang.from(tail)
    return term
  end

  def erlang_map(size = self.size, depth: 0, &block)
    arity = size
    pairs = if block_given?
      arity.times.map(&block)
    else
      arity.times.map { [random_erlang_term(size / 2, depth: depth - 1), random_erlang_term(size / 2, depth: depth - 1)] }
    end
    pairs = pairs.flat_map { |pair| pair }
    term = Erlang::Map[*pairs]
    return term
  end
  alias :random_erlang_map :erlang_map

  def erlang_new_float
    float_string = nil
    float_object = nil
    while float_string.nil? or float_object.to_s.include?("Infinity")
      e = range(-323, 308)
      sign = (range(0, 1) == 0) ? '' : '-'
      integer = range(0, 9)
      fractional = Array.new(20); 20.times { |i| fractional[i] = range(0, 9) }
      float_string = "#{sign}#{integer}.#{fractional.join}e#{(e >= 0) ? '+' : ''}#{e}"
      float_object = ::BigDecimal.new(::BigDecimal.new(float_string).to_s).to_f
    end
    return Erlang::Float[float_string]
  end

  def erlang_nil
    return Erlang::Nil
  end
  alias :random_erlang_nil :erlang_nil

  def erlang_pid(size = self.size)
    return Erlang::Pid[random_erlang_atom(size), non_negative_integer, non_negative_integer, non_negative_integer]
  end
  alias :random_erlang_pid :erlang_pid

  def erlang_port(size = self.size)
    return Erlang::Port[random_erlang_atom(size), non_negative_integer, non_negative_integer]
  end
  alias :random_erlang_port :erlang_port

  def erlang_reference(size = self.size, old: false)
    ids = (old) ? non_negative_integer : Rantly(size) { non_negative_integer }
    return Erlang::Reference[random_erlang_atom(size), non_negative_integer, ids]
  end

  def erlang_string(size = self.size, printable: false)
    return Erlang::String[(printable) ? random_printable_bytes(size) : random_bytes(size)]
  end

  def erlang_tuple(size = self.size, depth: 0, &block)
    arity = size
    elements = if block_given?
      array(arity, &block)
    else
      array(arity) { random_erlang_term(size / 2, depth: depth - 1) }
    end
    return Erlang::Tuple.new(elements)
  end
  alias :random_erlang_tuple :erlang_tuple

  def random_erlang_atom(size = self.size)
    return freq(
      [1, :erlang_atom, size, printable: false, utf8: false],
      [1, :erlang_atom, size, printable: false, utf8: true ],
      [1, :erlang_atom, size, printable: true,  utf8: false],
      [1, :erlang_atom, size, printable: true,  utf8: true ]
    )
  end

  def random_erlang_binary(size = self.size)
    return freq(
      [1, :erlang_binary, size, printable: false],
      [1, :erlang_binary, size, printable: true ]
    )
  end

  def random_erlang_float
    return freq(
      [1, :erlang_float],
      [1, :erlang_new_float]
    )
  end

  def random_erlang_list(size = self.size, depth: 0, &block)
    return freq(
      [5, ->(gen) { gen.erlang_list(size, depth: depth, &block) }],
      [1, ->(gen) { gen.erlang_list_improper(size, depth: depth, &block) }]
    )
  end

  def random_erlang_reference(size = self.size)
    return freq(
      [1, :erlang_reference, size, old: false],
      [1, :erlang_reference, size, old: true ]
    )
  end

  def random_erlang_string(size = self.size)
    return freq(
      [1, :erlang_string, size, printable: false],
      [1, :erlang_string, size, printable: true ]
    )
  end

  def random_erlang_term(size = self.size, depth: 1)
    if depth <= 0
      return freq(
        [1, :random_erlang_atom, size],
        [1, :random_erlang_bitstring, size],
        [1, :random_erlang_export, size],
        [1, :random_erlang_float],
        [1, :random_erlang_integer],
        [1, :random_erlang_nil],
        [1, :random_erlang_pid, size],
        [1, :random_erlang_port, size],
        [1, :random_erlang_reference, size],
        [1, :random_erlang_string, size]
      )
    else
      return freq(
        [1, :random_erlang_atom, size],
        [1, :random_erlang_bitstring, size],
        [1, :random_erlang_export, size],
        [1, :random_erlang_float],
        [1, :random_erlang_integer],
        [1, :random_erlang_list, size, depth: depth],
        [1, :random_erlang_map, size, depth: depth],
        [1, :random_erlang_nil],
        [1, :random_erlang_pid, size],
        [1, :random_erlang_port, size],
        [1, :random_erlang_reference, size],
        [1, :random_erlang_string, size],
        [1, :random_erlang_tuple, size, depth: depth]
      )
    end
  end

  # def erlang_etf_atom(size = self.size)
  #   return Erlang::ETF::Atom.new(random_string(size))
  # end

  # def erlang_etf_atom_utf8(size = self.size)
  #   return Erlang::ETF::AtomUTF8.new(utf8_string(size))
  # end

  # def erlang_etf_binary(size = self.size)
  #   return Erlang::ETF::Binary.new(random_string(size))
  # end

  # def erlang_etf_bit_binary(size = self.size, bits = self.range(1, 8))
  #   return Erlang::ETF::BitBinary.new(bits, random_string(size))
  # end

  # def erlang_etf_export(size = self.size, &block)
  #   mod, function, arity = if block_given?
  #     instance_exec(&block)
  #   else
  #     [
  #       random_erlang_etf_atom(range(0, size & 0xff)),
  #       random_erlang_etf_atom(range(0, size & 255)),
  #       Erlang::ETF::SmallInteger.new(range(0, size & 255))
  #     ]
  #   end
  #   return Erlang::ETF::Export.new(mod, function, arity)
  # end

  # def erlang_etf_float
  #   float_string = ('%.20e' % (float * choose(range(0, 1), range(0, 100000000000000000000000000000)))).ljust(31, "\000")
  #   return Erlang::ETF::Float.new(float_string)
  # end

  # def erlang_etf_integer
  #   int = freq(
  #     [1, :range, Erlang::ETF::Extensions::Integer::INT32_MIN, Erlang::ETF::Extensions::Integer::UINT8_MIN - 1],
  #     [1, :range, Erlang::ETF::Extensions::Integer::UINT8_MAX + 1, Erlang::ETF::Extensions::Integer::INT32_MAX]
  #   )
  #   return Erlang::ETF::Integer.new(int)
  # end

  # def erlang_etf_large_big
  #   integer = freq(
  #     [1, :range, ERLANG_ETF_LARGE_BIG_MIN, ERLANG_ETF_SMALL_BIG_MIN - 1],
  #     [1, :range, ERLANG_ETF_SMALL_BIG_MAX + 1, ERLANG_ETF_LARGE_BIG_MAX]
  #   )
  #   return Erlang::ETF::LargeBig.new(integer)
  # end

  # def erlang_etf_large_tuple(size = self.size, depth = 0, &block)
  #   arity = (size >= 256) ? size : 256
  #   elements = if block_given?
  #     array(arity, &block)
  #   else
  #     array(arity) { random_erlang_etf_term(size / 2, depth - 1) }
  #   end
  #   return Erlang::ETF::LargeTuple.new(elements)
  # end

  # def erlang_etf_list(size = self.size, depth = 0, &block)
  #   length = size
  #   elements = if block_given?
  #     array(length, &block)
  #   else
  #     array(length) { random_erlang_etf_term(size / 2, depth - 1) }
  #   end
  #   tail = Erlang::ETF::Nil
  #   return Erlang::ETF::List.new(elements, tail)
  # end

  # def erlang_etf_list_improper(size = self.size, depth = 0, tail = nil, &block)
  #   length = size
  #   elements = if block_given?
  #     array(length, &block)
  #   else
  #     array(length) { random_erlang_etf_term(size / 2, depth - 1) }
  #   end
  #   if tail.nil?
  #     tail = random_erlang_etf_term(size / 2, depth - 1)
  #   elsif tail.is_a?(Proc)
  #     tail = instance_exec(&tail)
  #   end
  #   while tail.equal?(Erlang::ETF::Nil) or (tail.is_a?(Erlang::ETF::List) and not tail.improper?)
  #     tail = random_erlang_etf_term(size / 2, depth - 1)
  #   end
  #   return Erlang::ETF::List.new(elements, tail)
  # end

  # def erlang_etf_map(size = self.size, depth = 0, &block)
  #   arity = size
  #   pairs = if block_given?
  #     array(arity, &block)
  #   else
  #     array(arity) { [random_erlang_etf_term(size / 2, depth - 1), random_erlang_etf_term(size / 2, depth - 1)] }
  #   end
  #   return Erlang::ETF::Map.new(pairs)
  # end

  # def erlang_etf_new_float
  #   return Erlang::ETF::NewFloat.new(float)
  # end

  # def erlang_etf_new_reference(size = self.size, &block)
  #   node, creation, ids = if block_given?
  #     instance_exec(&block)
  #   else
  #     [
  #       random_erlang_etf_atom(range(0, size & 0xff)),
  #       range(0, size & 0x3),
  #       array(size) { range(0, size & 0xffff) }
  #     ]
  #   end
  #   return Erlang::ETF::NewReference.new(node, creation, ids)
  # end

  # def erlang_etf_nil
  #   return Erlang::ETF::Nil
  # end

  # def erlang_etf_pid(size = self.size, &block)
  #   node, id, serial, creation = if block_given?
  #     instance_exec(&block)
  #   else
  #     [
  #       random_erlang_etf_atom(range(0, size & 0xff)),
  #       range(0, size & 0x7fff),
  #       range(0, size & 0x1fff),
  #       range(0, size & 0x3)
  #     ]
  #   end
  #   return Erlang::ETF::Pid.new(node, id, serial, creation)
  # end

  # def erlang_etf_port(size = self.size, &block)
  #   node, id, creation = if block_given?
  #     instance_exec(&block)
  #   else
  #     [
  #       random_erlang_etf_atom(range(0, size & 0xff)),
  #       range(0, size & 0xfffffff),
  #       range(0, size & 0x3)
  #     ]
  #   end
  #   return Erlang::ETF::Port.new(node, id, creation)
  # end

  # def erlang_etf_reference(size = self.size, &block)
  #   node, id, creation = if block_given?
  #     instance_exec(&block)
  #   else
  #     [
  #       random_erlang_etf_atom(range(0, size & 0xff)),
  #       range(0, size & 0xffff),
  #       range(0, size & 0x3)
  #     ]
  #   end
  #   return Erlang::ETF::Reference.new(node, id, creation)
  # end

  # def erlang_etf_small_atom(size = self.size)
  #   return Erlang::ETF::SmallAtom.new(random_string(size))
  # end

  # def erlang_etf_small_atom_utf8(size = self.size)
  #   return Erlang::ETF::SmallAtomUTF8.new(utf8_string(size))
  # end

  # def erlang_etf_small_big
  #   integer = freq(
  #     [1, :range, ERLANG_ETF_SMALL_BIG_MIN, Erlang::ETF::Extensions::Integer::INT32_MIN - 1],
  #     [1, :range, Erlang::ETF::Extensions::Integer::INT32_MAX + 1, ERLANG_ETF_SMALL_BIG_MAX]
  #   )
  #   return Erlang::ETF::SmallBig.new(integer)
  # end

  # def erlang_etf_small_integer
  #   int = range(Erlang::ETF::Extensions::Integer::UINT8_MIN, Erlang::ETF::Extensions::Integer::UINT8_MAX)
  #   return Erlang::ETF::SmallInteger.new(int)
  # end

  # def erlang_etf_small_tuple(size = self.size, depth = 0, &block)
  #   arity = (size >= 256) ? 255 : size
  #   elements = if block_given?
  #     array(arity, &block)
  #   else
  #     array(arity) { random_erlang_etf_term(size / 2, depth - 1) }
  #   end
  #   return Erlang::ETF::SmallTuple.new(elements)
  # end

  # def erlang_etf_string(size = self.size)
  #   return Erlang::ETF::String.new(random_string(size))
  # end

  # def random_erlang_etf_atom(size = self.size)
  #   return freq(
  #     [1, :erlang_etf_atom, size],
  #     [1, :erlang_etf_atom_utf8, size],
  #     [1, :erlang_etf_small_atom, size],
  #     [1, :erlang_etf_small_atom_utf8, size]
  #   )
  # end

  # def random_erlang_etf_bitstring(size = self.size, bits = self.range(1, 8))
  #   return freq(
  #     [1, :erlang_etf_binary, size],
  #     [1, :erlang_etf_bit_binary, size, bits]
  #   )
  # end

  # def random_erlang_etf_integer
  #   return freq(
  #     [10, :erlang_etf_small_integer],
  #     [10, :erlang_etf_integer],
  #     [ 2, :erlang_etf_small_big],
  #     [ 1, :erlang_etf_large_big]
  #   )
  # end

  # def random_erlang_etf_list(size = self.size, depth = 0, &block)
  #   return freq(
  #     [5, ->(gen) { gen.erlang_etf_list(size, depth, &block) }],
  #     [1, ->(gen) { gen.erlang_etf_list_improper(size, depth, &block) }]
  #   )
  # end

  # def random_erlang_etf_tuple(size = self.size, depth = 0, &block)
  #   return freq(
  #     [10, ->(gen) { gen.erlang_etf_small_tuple(size, depth, &block) }],
  #     [ 1, ->(gen) { gen.erlang_etf_large_tuple(size, depth, &block) }]
  #   )
  # end

  # def random_erlang_etf_term(size = self.size, depth = 1)
  #   if depth <= 0
  #     return freq(
  #       [1, :random_erlang_etf_atom, size],
  #       [1, :random_erlang_etf_bitstring, size],
  #       [1, :erlang_etf_export, size],
  #       [1, :erlang_etf_float],
  #       [1, :random_erlang_etf_integer],
  #       [1, :erlang_etf_new_float],
  #       [1, :erlang_etf_new_reference, size],
  #       [1, :erlang_etf_nil],
  #       [1, :erlang_etf_pid, size],
  #       [1, :erlang_etf_port, size],
  #       [1, :erlang_etf_reference, size],
  #       [1, :erlang_etf_string, size]
  #     )
  #   else
  #     return freq(
  #       [1, :random_erlang_etf_atom, size],
  #       [1, :random_erlang_etf_bitstring, size],
  #       [1, :erlang_etf_export, size],
  #       [1, :erlang_etf_float],
  #       [1, :random_erlang_etf_integer],
  #       [1, :random_erlang_etf_list, size, depth],
  #       [1, :erlang_etf_map, size, depth],
  #       [1, :erlang_etf_new_float],
  #       [1, :erlang_etf_new_reference, size],
  #       [1, :erlang_etf_nil],
  #       [1, :erlang_etf_pid, size],
  #       [1, :erlang_etf_port, size],
  #       [1, :erlang_etf_reference, size],
  #       [1, :erlang_etf_string, size],
  #       [1, :random_erlang_etf_tuple, size, depth]
  #     )
  #   end
  # end

  # def random_little_endian_string(size = self.size, bytes = nil)
  #   bytes ||= SecureRandom.random_bytes(size)
  #   loop do
  #     bytes.gsub!(/\x00*\z/, '')
  #     break if bytes.bytesize == size
  #     if bytes.bytesize < size
  #       bytes += SecureRandom.random_bytes(size - bytes.bytesize)
  #     end
  #   end
  #   return bytes
  # end

  def non_negative_integer(n = nil)
    return integer(n).abs
  end

  def random_bytes(size = self.size)
    return SecureRandom.random_bytes(size)
  end

  def random_printable_bytes(size = self.size)
    bytes = random_utf8_bytes(size)
    loop do
      break if !!(PRINTABLE =~ bytes)
      bytes = bytes.chars.select { |char| !!(PRINTABLE =~ char) }.join
      if bytes.bytesize < size
        bytes += random_utf8_bytes(size - bytes.bytesize)
      end
    end
    return bytes
  end

  def random_utf8_bytes(size = self.size)
    bytes = random_bytes(size).force_encoding(UTF8_ENCODING)
    loop do
      break if bytes.valid_encoding?
      bytes = bytes.chars.select(&:valid_encoding?).join
      if bytes.bytesize < size
        bytes += random_bytes(size - bytes.bytesize).force_encoding(UTF8_ENCODING)
      end
    end
    return bytes
  end

  # def random_string(size = self.size)
  #   bytes = SecureRandom.random_bytes(size)
  #   _, bytes = Erlang::Terms.validate_encoding(bytes)
  #   return bytes
  # end

  # def utf8_string(size = self.size, bytes = nil)
  #   bytes ||= SecureRandom.random_bytes(size).force_encoding(UTF8_ENCODING)
  #   loop do
  #     break if bytes.valid_encoding?
  #     bytes = bytes.chars.select(&:valid_encoding?).join
  #     if bytes.bytesize < size
  #       bytes += SecureRandom.random_bytes(size - bytes.bytesize).force_encoding(UTF8_ENCODING)
  #     end
  #   end
  #   return bytes
  # end

end
