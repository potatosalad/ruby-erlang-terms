module Erlang
  # A `Binary` is a series of bytes.
  #
  # ### Creating Binaries
  #
  #     Erlang::Binary["test"]
  #     # => Erlang::Binary["test"]
  #
  class Binary
    include Erlang::Term
    include Erlang::Immutable

    # Return the data for this `Erlang::Binary`
    # @return [::String]
    attr_reader :data

    # Return the bits for this `Erlang::Binary`
    # @return [::Integer]
    # @!parse attr_reader :bits
    def bits
      return 8
    end

    class << self
      # Create a new `Binary` populated with the given `data`.
      # @param data [::String, Symbol, ::Enumerable, Integer] The content of the `Binary`
      # @return [Binary]
      # @raise [ArgumentError] if `data` cannot be coerced to be a `::String`
      def [](*data)
        return Erlang.iolist_to_binary(data)
      end

      # Return an empty `Binary`. If used on a subclass, returns an empty instance
      # of that class.
      #
      # @return [Binary]
      def empty
        return @empty ||= self.new
      end

      # Compares `a` and `b` and returns whether they are less than,
      # equal to, or greater than each other.
      #
      # @param a [Binary] The left argument
      # @param b [Binary] The right argument
      # @return [-1, 0, 1]
      # @raise [ArgumentError] if `a` or `b` is not a `Binary`
      def compare(a, b)
        return Erlang::Bitstring.compare(a, b)
      end

      # Concatenates list of `Binary` or `Bitstring` items into a single `Binary` or `Bitstring`.
      #
      # @example
      #   Erlang::Binary.concat(Erlang::Bitstring[1, bits: 2], Erlang::Binary[255])
      #   # => Erlang::Bitstring[127, 3, bits: 2]
      #
      # @param iodata [Binary, Bitstring] The list of bitstrings
      # @return [Binary, Bitstring]
      def concat(*iodata)
        return iodata.reduce(Erlang::EmptyBinary) { |acc, item| acc.concat(item) }
      end

      # Returns an unsigned `Integer` which is the `endianness` based version of the `subject`.
      #
      # @param subject [::String, Binary] The string to decode
      # @param endianness [:big, :little] The endianness of the subject
      # @return [Integer]
      # @raise [ArgumentError] if `subject` is not a string or `endianness` is not `:big` or `:little`
      def decode_unsigned(subject, endianness = :big)
        subject = subject.to_s if subject.kind_of?(Erlang::Binary)
        raise ArgumentError, 'subject must be a String' if not subject.is_a?(::String)
        case endianness
        when :big, :little
          bits = 0
          bytes = subject.unpack(Erlang::Terms::UINT8_SPLAT)
          bytes = bytes.reverse if endianness == :big
          return bytes.inject(0) do |unsigned, n|
            unsigned = unsigned + (n << bits)
            bits += 8
            next unsigned
          end
        else
          raise ArgumentError, 'endianness must be :big or :little'
        end
      end

      # Returns a `::String` which is the `endianness` based version of the unsigned `subject`.
      #
      # @param subject [Integer] The unsigned integer to encode
      # @param endianness [:big, :little] The endianness of the subject
      # @return [::String]
      # @raise [ArgumentError] if `subject` is not an integer or `endianness` is not `:big` or `:little`
      def encode_unsigned(unsigned, endianness = :big)
        raise ArgumentError, 'unsigned must be a non-negative Integer' if not unsigned.is_a?(::Integer) or unsigned < 0
        case endianness
        when :big, :little
          n = unsigned
          bytes = []
          loop do
            bytes << (n & 255)
            break if (n >>= 8) == 0
          end
          bytes = bytes.reverse if endianness == :big
          return bytes.pack(Erlang::Terms::UINT8_SPLAT)
        else
          raise ArgumentError, 'endianness must be :big or :little'
        end
      end
    end

    # @private
    def initialize(data = nil)
      data = ::String.new if data.nil?
      data = data.data if data.is_a?(Erlang::Binary)
      raise ArgumentError, 'data must be a String' if not data.is_a?(::String)
      _, data = Erlang::Terms.utf8_encoding(data)
      @printable = Erlang::Terms.printable?(data)
      data = Erlang::Terms.binary_encoding(data) if not @printable
      @data = data.freeze
    end

    # @private
    def hash
      return @data.hash
    end

    # Returns the byte at the provided `position`.
    #
    # @param position [Integer] The position of the byte
    # @return [Integer]
    # @raise [ArgumentError] if `position` is not an `Integer`
    def at(position)
      raise ArgumentError, 'position must be an Integer' if not position.is_a?(::Integer)
      return @data.getbyte(position)
    end
    alias :[] :at

    # @return [Integer] the number of bits in this `Binary`
    def bitsize
      return (bytesize * bits)
    end

    # Return specific objects from the `Binary`. All overloads return `nil` if
    # the starting index is out of range.
    #
    # @overload bitslice(index)
    #   Returns a single bit at the given `index`. If `index` is negative,
    #   count backwards from the end.
    #
    #   @param index [Integer] The index to retrieve. May be negative.
    #   @return [Integer, nil]
    #   @example
    #     b = Erlang::Binary[1]
    #     b.bitslice(0)  # => 0
    #     b.bitslice(7)  # => 1
    #     b.bitslice(-1) # => 1
    #     b.bitslice(8)  # => nil
    #
    # @overload bitslice(index, length)
    #   Return a bitstring starting at `index` and continuing for `length`
    #   bits or until the end of the `Binary`, whichever occurs first.
    #
    #   @param start [Integer] The index to start retrieving bits from. May be
    #                          negative.
    #   @param length [Integer] The number of bits to retrieve.
    #   @return [Bitstring, Binary]
    #   @example
    #     b = Erlang::Binary[117]
    #     b.bitslice(0, 3) # => Erlang::Bitstring[3, bits: 3]
    #     b.bitslice(3, 5) # => Erlang::Bitstring[21, bits: 5]
    #     b.bitslice(9, 1) # => nil
    #
    # @overload bitslice(index..end)
    #   Return a bitstring starting at `index` and continuing to index
    #   `end` or the end of the `Binary`, whichever occurs first.
    #
    #   @param range [Range] The range of bits to retrieve.
    #   @return [Bitstring, Binary]
    #   @example
    #     b = Erlang::Binary[117]
    #     b.bitslice(0...3) # => Erlang::Bitstring[3, bits: 3]
    #     b.bitslice(3...8) # => Erlang::Bitstring[21, bits: 5]
    #     b.bitslice(9..-1) # => nil
    #
    # @see Erlang::Bitstring#bitslice
    def bitslice(*args)
      return Erlang::Bitstring.new(@data, 8).bitslice(*args)
    end

    # @return [Integer] the number of bytes in this `Binary`
    def bytesize
      return @data.bytesize
    end
    alias :size :bytesize

    # Concatenates list of `Binary` or `Bitstring` items into a single `Binary` or `Bitstring`.
    #
    # @example
    #   Erlang::Binary["a"].concat(Erlang::Bitstring[3, bits: 3]).concat(Erlang::Bitstring[2, bits: 5])
    #   # => "ab"
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
      if other.kind_of?(Erlang::Bitstring) and other.bits != 8
        return Erlang::Bitstring[@data, other.data, bits: other.bits]
      else
        return Erlang::Binary[@data, other.data]
      end
    end
    alias :+ :concat

    # Returns a new `Binary` containing `n` copies of itself. `n` must be greater than or equal to 0.
    # @param n [Integer] The number of copies
    # @return [Binary]
    # @raise [ArgumentError] if `n` is less than 0
    def copy(n = 1)
      raise ArgumentError, 'n must be a non-negative Integer' if not n.is_a?(::Integer) or n < 0
      return self if n == 1
      return Erlang::Binary[(@data * n)]
    end

    # Returns an unsigned `Integer` which is the `endianness` based version of this `Binary`.
    # @param endianness [:big, :little] The endianness of this `Binary`
    # @return [Integer]
    # @see Erlang::Binary.decode_unsigned
    def decode_unsigned(endianness = :big)
      return Erlang::Binary.decode_unsigned(@data, endianness)
    end

    # Call the given block once for each bit in the `Binary`, passing each
    # bit from first to last successively to the block. If no block is given,
    # returns an `Enumerator`.
    #
    # @return [self]
    # @yield [Integer]
    def each_bit
      return enum_for(:each_bit) unless block_given?
      index = 0
      bitsize = self.bitsize
      @data.each_byte do |byte|
        loop do
          break if index == bitsize
          bit = (byte >> (7 - (index & 7))) & 1
          yield bit
          index += 1
          break if (index & 7) == 0
        end
      end
      return self
    end

    # Split the bits in this `Binary` in groups of `number` bits, and yield
    # each group to the block (as a `List`). If no block is given, returns
    # an `Enumerator`.
    #
    # @example
    #   b = Erlang::Binary[117]
    #   b.each_bitslice(4).to_a # => [Erlang::Bitstring[7, bits: 4], Erlang::Bitstring[5, bits: 4]]
    #
    # @return [self, Enumerator]
    # @yield [Binary, Bitstring] Once for each bitstring.
    # @see Erlang::Bitstring#each_bitslice
    def each_bitslice(number, &block)
      return enum_for(:each_bitslice, number) unless block_given?
      bitstring = Erlang::Bitstring.new(@data, 8)
      bitstring.each_bitslice(number, &block)
      return self
    end

    # Call the given block once for each byte in the `Binary`, passing each
    # byte from first to last successively to the block. If no block is given,
    # returns an `Enumerator`.
    #
    # @return [self]
    # @yield [Integer]
    def each_byte(&block)
      return enum_for(:each_byte) unless block_given?
      @data.each_byte(&block)
      return self
    end

    # Returns true if this `Binary` is empty.
    #
    # @return [Boolean]
    def empty?
      return @data.empty?
    end

    # Return true if `other` has the same type and contents as this `Binary`.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean]
    def eql?(other)
      return true if other.equal?(self)
      if instance_of?(other.class)
        return @data.eql?(other.data)
      elsif other.kind_of?(Erlang::Bitstring)
        return !!(Erlang::Bitstring.compare(other, self) == 0)
      else
        return !!(Erlang.compare(other, self) == 0)
      end
    end
    alias :== :eql?

    # Returns the first byte of this `Binary`.
    # @return [Integer]
    # @raise [NotImplementedError] if this `Binary` is empty
    def first
      raise NotImplementedError if empty?
      return at(0)
    end

    # Returns the last byte of this `Binary`.
    # @return [Integer]
    # @raise [NotImplementedError] if this `Binary` is empty
    def last
      raise NotImplementedError if empty?
      return at(-1)
    end

    # Returns the section of this `Binary` starting at `position` of `length`.
    #
    # @param position [Integer] The starting position
    # @param length [Integer] The non-negative length
    # @return [Binary]
    # @raise [ArgumentError] if `position` is not an `Integer` or `length` is not a non-negative `Integer`
    def part(position, length)
      raise ArgumentError, 'position must be an Integer' if not position.is_a?(::Integer)
      raise ArgumentError, 'length must be a non-negative Integer' if not length.is_a?(::Integer) or length < 0
      return Erlang::Binary[@data.byteslice(position, length)]
    end

    # Return the contents of this `Binary` as a Erlang-readable `::String`.
    #
    # @example
    #     Erlang::Binary["test"].erlang_inspect
    #     # => "<<\"test\"/utf8>>"
    #     # Pass `raw` as `true` for the decimal version
    #     Erlang::Binary["test"].erlang_inspect(true)
    #     # => "<<116,101,115,116>>"
    #
    # @return [::String]
    def erlang_inspect(raw = false)
      result = '<<'
      if raw == false and @printable
        result << @data.inspect
        result << '/utf8'
      else
        result << @data.bytes.join(',')
      end
      result << '>>'
      return result
    end

    # @return [::String] the nicely formatted version of the `Binary`
    def inspect
      return @data.inspect
    end

    # @return [Atom] the `Atom` version of the `Binary`
    def to_atom
      return Erlang::Atom[@data]
    end

    # @return [self] the `Binary` version of the `Binary`
    def to_binary
      return self
    end

    # @param bits [Integer] The number of bits to keep for the last byte
    # @return [Bitstring, self] the `Bitstring` version of the `Binary`
    def to_bitstring(bits = 8)
      if bits == 8
        return self
      else
        return Erlang::Bitstring[@data, bits: bits]
      end
    end

    # @return [List] the `List` version of the `Binary`
    def to_list
      return Erlang::List.from_enum(@data.bytes)
    end

    # @return [String] the `String` version of the `Binary`
    def to_string
      return Erlang::String[@data]
    end

    # @return [::String] the string version of the `Binary`
    def to_s
      return @data
    end
    alias :to_str :to_s

    # @return [::String]
    # @private
    def marshal_dump
      return @data
    end

    # @private
    def marshal_load(data)
      initialize(data)
      __send__(:immutable!)
      return self
    end
  end

  # The canonical empty `Binary`. Returned by `Binary[]` when
  # invoked with no arguments; also returned by `Binary.empty`. Prefer using this
  # one rather than creating many empty binaries using `Binary.new`.
  #
  # @private
  EmptyBinary = Erlang::Binary.empty
end
