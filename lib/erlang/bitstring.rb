module Erlang
  # A `Bitstring` is a series of bits.
  #
  # ### Creating Bitstrings
  #
  #     Erlang::Bitstirng["test", bits: 7]
  #     # => Erlang::Bitstring[116, 101, 115, 4, bits: 3]
  #
  class Bitstring
    include Erlang::Term
    include Erlang::Immutable

    # Return the data for this `Bitstring`
    # @return [::String]
    attr_reader :data

    # Return the bits for this `Bitstring`
    # @return [::Integer]
    attr_reader :bits

    class << self
      # Create a new `Bitstring` populated with the given `data` and `bits`.
      # @param data [::String, Symbol, ::Enumerable, Integer] The content of the `Binary`
      # @param bits [Integer] The number of bits to keep on the last byte
      # @return [Bitstring, Binary]
      # @raise [ArgumentError] if `data` cannot be coerced to be a `::String` or `bits` is not between 1 and 8
      def [](*data, bits: 8)
        return EmptyBinary if data.empty?
        raise ArgumentError, 'bits must be an Integer' if not bits.is_a?(::Integer)
        raise ArgumentError, 'bits must be between 1 and 8' if bits < 1 or bits > 8
        binary = Erlang.iolist_to_binary(data)
        if bits == 8 or binary.empty?
          return binary
        else
          return new(binary, bits)
        end
      end

      def empty
        return Erlang::EmptyBinary
      end

      # Compares `a` and `b` and returns whether they are less than,
      # equal to, or greater than each other.
      #
      # @param a [Bitstring, Binary] The left argument
      # @param b [Bitstring, Binary] The right argument
      # @return [-1, 0, 1]
      # @raise [ArgumentError] if `a` or `b` is not a `Bitstring` or `Binary`
      def compare(a, b)
        raise ArgumentError, "'a' must be of Erlang::Binary or Erlang::Bitstring type" if not a.kind_of?(Erlang::Binary) and not a.kind_of?(Erlang::Bitstring)
        raise ArgumentError, "'b' must be of Erlang::Binary or Erlang::Bitstring type" if not b.kind_of?(Erlang::Binary) and not b.kind_of?(Erlang::Bitstring)
        c = a.bitsize <=> b.bitsize
        return a.data <=> b.data if c == 0
        c = 0
        i = 0
        abytes = a.bytesize
        bbytes = b.bytesize
        abytes -= 1 if a.bits != 8
        bbytes -= 1 if b.bits != 8
        while c == 0 and i < abytes and i < bbytes
          c = a.data.getbyte(i) <=> b.data.getbyte(i)
          i += 1
        end
        if c == 0
          if (a.bits != 8 and i == abytes and i < bbytes) or (b.bits != 8 and i == bbytes and i < abytes) or (a.bits != 8 and b.bits != 8)
            abyte = a.data.getbyte(i)
            bbyte = b.data.getbyte(i)
            askip = 8 - a.bits
            bskip = 8 - b.bits
            i = 0
            loop do
              if i == a.bits and i == b.bits
                c = 0
                break
              elsif i == a.bits
                c = -1
                break
              elsif i == b.bits
                c = 1
                break
              end
              abit = (abyte >> (7 - ((i + askip) & 7))) & 1
              bbit = (bbyte >> (7 - ((i + bskip) & 7))) & 1
              c = abit <=> bbit
              break if c != 0
              i += 1
              break if (i & 7) == 0
            end
          elsif i >= a.bytesize and i < b.bytesize
            c = -1
          elsif i >= b.bytesize and i < a.bytesize
            c = 1
          end
        end
        return c
      end

      # Concatenates list of `Binary` or `Bitstring` items into a single `Binary` or `Bitstring`.
      #
      # @example
      #   Erlang::Bitstring.concat(Erlang::Bitstring[1, bits: 2], Erlang::Binary[255])
      #   # => Erlang::Bitstring[127, 3, bits: 2]
      #
      # @param iodata [Binary, Bitstring] The list of bitstrings
      # @return [Binary, Bitstring]
      def concat(*iodata)
        return iodata.reduce(Erlang::EmptyBinary) { |acc, item| acc.concat(item) }
      end
    end

    # @private
    def initialize(data = nil, bits = 8)
      raise ArgumentError, 'bits must be an Integer' if not bits.is_a?(::Integer)
      raise ArgumentError, 'bits must be between 1 and 8' if bits < 1 or bits > 8
      data = ::String.new if data.nil?
      data = data.data if data.is_a?(Erlang::Binary)
      raise ArgumentError, 'data must be a String' if not data.is_a?(::String)
      data = Erlang::Terms.binary_encoding(data)
      if data.bytesize > 0
        data.setbyte(-1, ((data.getbyte(-1) << (8 - bits)) & 255) >> (8 - bits))
      end
      @data = data.freeze
      @bits = bits.freeze
      @bitsize = (@data.bytesize == 0) ? 0 : (((@data.bytesize - 1) * 8) + @bits)
    end

    # @private
    def hash
      hash = @data.hash
      return (hash << 5) - hash + bits.hash
    end

    # @raise [NotImplementedError]
    def at(position)
      raise NotImplementedError
    end
    alias :[] :at

    # @return [Integer] the number of bits in this `Bitstring`
    def bitsize
      return @bitsize
    end

    # @private
    BIT_PACK = 'B*'.freeze

    # Return specific objects from the `Bitstring`. All overloads return `nil` if
    # the starting index is out of range.
    #
    # @overload bitslice(index)
    #   Returns a single bit at the given `index`. If `index` is negative,
    #   count backwards from the end.
    #
    #   @param index [Integer] The index to retrieve. May be negative.
    #   @return [Integer, nil]
    #   @example
    #     b = Erlang::Bitstring[2, bits: 2]
    #     b.bitslice(0)  # => 1
    #     b.bitslice(1)  # => 0
    #     b.bitslice(-1) # => 0
    #     b.bitslice(2)  # => nil
    #
    # @overload bitslice(index, length)
    #   Return a bitstring starting at `index` and continuing for `length`
    #   bits or until the end of the `Bitstring`, whichever occurs first.
    #
    #   @param start [Integer] The index to start retrieving bits from. May be
    #                          negative.
    #   @param length [Integer] The number of bits to retrieve.
    #   @return [Bitstring, Binary]
    #   @example
    #     b = Erlang::Bitstring[1, 117, bits: 7]
    #     b.bitslice(0, 11) # => Erlang::Bitstring[1, 7, bits: 3]
    #     b.bitslice(11, 4) # => Erlang::Bitstring[5, bits: 4]
    #     b.bitslice(16, 1) # => nil
    #
    # @overload bitslice(index..end)
    #   Return a bitstring starting at `index` and continuing to index
    #   `end` or the end of the `Bitstring`, whichever occurs first.
    #
    #   @param range [Range] The range of bits to retrieve.
    #   @return [Bitstring, Binary]
    #   @example
    #     b = Erlang::Bitstring[1, 117, bits: 7]
    #     b.bitslice(0...11)  # => Erlang::Bitstring[1, 7, bits: 3]
    #     b.bitslice(11...15) # => Erlang::Bitstring[5, bits: 4]
    #     b.bitslice(16..-1)  # => nil
    #
    # @see Erlang::Binary#bitslice
    def bitslice(arg, length = (missing_length = true))
      if missing_length
        if arg.is_a?(Range)
          from, to = arg.begin, arg.end
          from += bitsize if from < 0
          return nil if from < 0
          to   += bitsize if to < 0
          to   += 1       if !arg.exclude_end?
          length = to - from
          length = 0 if length < 0
          length = bitsize - from if (from + length) > bitsize
          return nil if length < 0
          l8 = length.div(8)
          l1 = length % 8
          pad = 8 - l1
          enum = each_bit
          skip = from
          enum = enum.drop_while {
            if skip > 0
              skip -= 1
              next true
            else
              next false
            end
          }
          head = enum.take(length)
          if l1 == 0
            return Erlang::Binary[[head.join].pack(BIT_PACK)]
          else
            tail = head[-l1..-1]
            head = head[0...-l1]
            tail = ([0] * pad).concat(tail)
            return Erlang::Bitstring[[[head.join, tail.join].join].pack(BIT_PACK), bits: l1]
          end
        else
          arg += bitsize if arg < 0
          return nil if arg < 0
          return nil if arg >= bitsize
          a8 = arg.div(8)
          a1 = arg % 8
          byte = @data.getbyte(a8)
          return nil if byte.nil?
          return (byte >> ((@bits - a1 - 1) & 7)) & 1
        end
      else
        return nil if length < 0
        arg += bitsize if arg < 0
        return nil if arg < 0
        length = bitsize - arg if (arg + length) > bitsize
        return nil if length < 0
        l8 = length.div(8)
        l1 = length % 8
        pad = 8 - l1
        enum = each_bit
        skip = arg
        enum = enum.drop_while {
          if skip > 0
            skip -= 1
            next true
          else
            next false
          end
        }
        head = enum.take(length)
        if l1 == 0
          return Erlang::Binary[[head.join].pack(BIT_PACK)]
        else
          tail = head[-l1..-1]
          head = head[0...-l1]
          tail = ([0] * pad).concat(tail)
          return Erlang::Bitstring[[[head.join, tail.join].join].pack(BIT_PACK), bits: l1]
        end
      end
    end

    # @return [Integer] the number of bytes in this `Bitstring`
    def bytesize
      return @data.bytesize
    end
    alias :size :bytesize

    # Concatenates list of `Binary` or `Bitstring` items into a single `Binary` or `Bitstring`.
    #
    # @example
    #   Erlang::Bitstring[3, bits: 3].concat(Erlang::Bitstring[1, bits: 5])
    #   # => "a"
    #
    # @param iodata [Binary, Bitstring] The list of bitstrings
    # @return [Binary, Bitstring]
    def concat(*other)
      if other.size == 1 and (other[0].kind_of?(Erlang::Binary) or other[0].kind_of?(Erlang::Bitstring))
        other = other[0]
      else
        other = Erlang::Binary[*other]
      end
      return other if empty?
      return self if other.empty?
      if @bits == 8
        return to_binary.concat(other)
      else
        bits = (@bits + other.bits) % 8
        head = [*each_bit, *other.each_bit]
        if bits == 0
          return Erlang::Binary[[head.join].pack(BIT_PACK)]
        else
          pad  = 8 - bits
          tail = head[-bits..-1]
          head = head[0...-bits]
          tail = ([0] * pad).concat(tail)
          return Erlang::Bitstring[[[head.join, tail.join].join].pack(BIT_PACK), bits: bits]
        end
      end
    end
    alias :+ :concat

    # @raise [NotImplementedError]
    def copy(n = 1)
      raise NotImplementedError
    end

    # @raise [NotImplementedError]
    def decode_unsigned(endianness = :big)
      raise NotImplementedError
    end

    # Call the given block once for each bit in the `Bitstring`, passing each
    # bit from first to last successively to the block. If no block is given,
    # returns an `Enumerator`.
    #
    # @return [self]
    # @yield [Integer]
    def each_bit
      return enum_for(:each_bit) unless block_given?
      index = 0
      headbits = (self.bytesize - 1) * 8
      skipbits = 8 - @bits
      @data.each_byte do |byte|
        loop do
          break if index == @bitsize
          if index >= headbits
            bit = (byte >> (7 - ((index + skipbits) & 7))) & 1
          else
            bit = (byte >> (7 - (index & 7))) & 1
          end
          yield bit
          index += 1
          break if (index & 7) == 0
        end
      end
      return self
    end

    # Split the bits in this `Bitstring` in groups of `number` bits, and yield
    # each group to the block (as a `List`). If no block is given, returns
    # an `Enumerator`.
    #
    # @example
    #   b = Erlang::Bitstring[117, bits: 7]
    #   b.each_bitslice(4).to_a # => [Erlang::Bitstring[14, bits: 4], Erlang::Bitstring[5, bits: 3]]
    #
    # @return [self, Enumerator]
    # @yield [Binary, Bitstring] Once for each bitstring.
    # @see Erlang::Bitstring#each_bitslice
    def each_bitslice(number)
      return enum_for(:each_bitslice, number) unless block_given?
      raise ArgumentError, 'number must be a positive Integer' if not number.is_a?(::Integer) or number < 1
      slices = bitsize.div(number) + ((bitsize % number == 0) ? 0 : 1)
      index  = 0
      loop do
        break if slices == 0
        yield(bitslice(index * number, number))
        slices -= 1
        index  += 1
      end
      return self
    end

    # @raise [NotImplementedError]
    def each_byte
      raise NotImplementedError
    end

    # Returns true if this `Bitstring` is empty.
    #
    # @return [Boolean]
    def empty?
      return @data.empty?
    end

    # Return true if `other` has the same type and contents as this `Bitstring`.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean]
    def eql?(other)
      return true if other.equal?(self)
      if instance_of?(other.class)
        return !!(self.class.compare(self, other) == 0)
      else
        return !!(Erlang.compare(other, self) == 0)
      end
    end
    alias :== :eql?

    # @raise [NotImplementedError]
    def first
      raise NotImplementedError
    end

    # @raise [NotImplementedError]
    def last
      raise NotImplementedError
    end

    # @raise [NotImplementedError]
    def part(position, length)
      raise NotImplementedError
    end

    # Return the contents of this `Bitstring` as a Erlang-readable `::String`.
    #
    # @example
    #     Erlang::Bitstring["test", bits: 3].erlang_inspect
    #     # => "<<116,101,115,4:3>>"
    #
    # @return [::String]
    def erlang_inspect(raw = false)
      return Erlang.inspect(Erlang::Binary.new(@data), raw: raw) if @bits == 8
      result = '<<'
      bytes = @data.bytes
      if last = bytes.pop
        result << bytes.join(',')
        result << ',' if not bytes.empty?
        if @bits == 8
          result << "#{last}"
        else
          result << "#{last}:#{@bits}"
        end
      end
      result << '>>'
      return result
    end

    # @return [::String] the nicely formatted version of the `Bitstring`
    def inspect
      return "Erlang::Bitstring[#{data.bytes.inspect[1..-2]}, bits: #{bits.inspect}]"
    end

    # @return [Binary] the `Binary` version of the `Bitstring` padded with zeroes
    def to_binary
      return EmptyBinary if empty?
      return Erlang::Binary[@data]
    end

    # @return [::String] the string version of the `Bitstring`
    def to_s
      return @data
    end
    alias :to_str :to_s

    # @return [::String]
    # @private
    def marshal_dump
      return [@data, @bits]
    end

    # @private
    def marshal_load(args)
      data, bits = args
      initialize(data, bits)
      __send__(:immutable!)
      return self
    end
  end
end
