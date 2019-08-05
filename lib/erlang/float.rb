require 'bigdecimal'

module Erlang
  # An `Float` is a literal constant float-precision number.
  #
  # ### Creating Floats
  #
  #     Erlang::Float["1.0e10"]
  #     # => 1.00000000000000000000e+10
  #     Erlang::Float[0]
  #     # => 0.00000000000000000000e+00
  #     Erlang::Float[-0.0, old: true]
  #     # => Erlang::Float["-0.00000000000000000000e+00", old: true]
  #     Erlang::Float[-1e308]
  #     # => -1.00000000000000000000e+308
  #     Erlang::Float[1e-308]
  #     # => 1.00000000000000000000e-308
  #
  class Float
    include Erlang::Term
    include Erlang::Immutable

    # Return the data for this `Float`
    # @return [::BigDecimal]
    attr_reader :data

    # Return the old flag for this `Float`
    # @return [::Boolean]
    attr_reader :old

    class << self
      # Create a new `Float` populated with the given `data`.
      # @param data [::BigDecimal, ::Float] The content of the `Float`
      # @param old [Boolean] Whether the `Float` should be considered old or not
      # @return [Float]
      # @raise [ArgumentError] if `data` cannot be coerced to be a `::BigDecimal`
      def [](data, old: false)
        if data.is_a?(::String)
          data = ::Kernel::BigDecimal(data)
        elsif data.is_a?(::Rational)
          data = ::Kernel::BigDecimal(data.to_f.to_s)
        elsif not data.is_a?(::BigDecimal)
          data = ::Kernel::BigDecimal(data.to_s)
        end
        return new(data, old)
      end

      # Compares `a` and `b` and returns whether they are less than,
      # equal to, or greater than each other.
      #
      # @param a [Float] The left argument
      # @param b [Float] The right argument
      # @return [-1, 0, 1]
      # @raise [ArgumentError] if `a` or `b` is not an `Float`
      def compare(a, b)
        raise ArgumentError, "'a' must be of Erlang::Float type" unless a.kind_of?(Erlang::Float)
        raise ArgumentError, "'b' must be of Erlang::Float type" unless b.kind_of?(Erlang::Float)
        return a.data <=> b.data
      end
    end

    # @private
    def initialize(data, old)
      raise ArgumentError, 'data must be a BigDecimal' if not data.is_a?(::BigDecimal)
      @data = data.freeze
      @old  = !!old
      if @old == false and @data != @data.to_f
        @data = ::Kernel::BigDecimal(@data.to_f.to_s).freeze
      end
      raise ArgumentError, "data cannot be positive or negative Infinity: #{data.inspect}" if @data.to_s.include?("Infinity")
    end

    # @private
    def hash
      return @data.hash
    end

    # If a `numeric` is the same type as `self`, returns an array containing `numeric` and `self`.
    # Otherwise, returns an array with both a numeric and num represented as `Float` objects.
    #
    # @param numeric [Erlang::Float, Numeric]
    # @return [::Array]
    def coerce(numeric)
      if numeric.is_a?(Erlang::Float)
        return [numeric, self]
      else
        return [numeric.to_f, to_f]
      end
    end

    # Return true if `other` has the same type and contents as this `Float`.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean]
    def eql?(other)
      return true if other.equal?(self)
      if instance_of?(other.class)
        return !!(self.data == other.data)
      else
        return !!(Erlang.compare(other, self) == 0)
      end
    end
    alias :== :eql?

    # Return the contents of this `Float` as a Erlang-readable `::String`.
    #
    # @example
    #     Erlang::Float[-1e308].erlang_inspect
    #     # => "-1.00000000000000000000e+308"
    #
    # @return [::String]
    def erlang_inspect(raw = false)
      return to_float_string
    end

    # @return [::String] the nicely formatted version of the `Float`
    def inspect
      if @old
        return "Erlang::Float[#{to_float_string.inspect}, old: true]"
      else
        float_string = to_float_string
        float_object = ::Kernel::Float(float_string)
        if Erlang::PositiveInfinity == float_object or Erlang::NegativeInfinity == float_object
          return "Erlang::Float[#{float_string.inspect}]"
        else
          return float_string
        end
      end
    end

    # @return [::String] the float string format of the `Float`
    def to_float_string
      string = @data.to_s
      sign = (string.getbyte(0) == 45) ? '-' : ''
      offset = (sign.bytesize == 1) ? 1 : 0
      dotpos = string.index(?.)
      epos = string.index(?e)
      if epos.nil?
        string << "e00"
        epos = string.index(?e)
      end
      if @data.zero?
        return Erlang::Terms.binary_encoding([
          sign,
          '0.00000000000000000000e+00'
        ].join)
      end
      integer = string.byteslice(offset, dotpos - offset)
      fractional = string.byteslice(dotpos + 1, epos - dotpos - 1)
      e = string.byteslice(epos + 1, string.bytesize - epos - 1).to_i
      while fractional.bytesize > 0 and integer == ?0 and e > -323
        b = fractional.getbyte(0)
        fractional = fractional.byteslice(1, fractional.bytesize - 1)
        e -= 1
        if b != 48
          integer.setbyte(0, b)
        end
      end
      if fractional.bytesize > 20
        fractional = fractional.byteslice(0, 20)
      elsif fractional.bytesize < 20
        fractional = fractional.ljust(20, ?0)
      end
      return Erlang::Terms.binary_encoding([
        sign,
        integer,
        '.',
        fractional,
        (e < 0) ? 'e-' : 'e+',
        e.abs.to_s.rjust(2, ?0)
      ].join)
    end

    # @return [::Float] the float version of the `Float`
    def to_f
      return @data.to_f
    end

    # @return [::String] the string version of the `Float`
    def to_s
      return to_float_string
    end
    alias :to_str :to_s

    # @return [::String]
    # @private
    def marshal_dump
      return [to_float_string, @old]
    end

    # @private
    def marshal_load(args)
      float_string, old = args
      initialize(::Kernel::BigDecimal(float_string), old)
      __send__(:immutable!)
      return self
    end

  end

  PositiveInfinity = (1.0 / 0.0).freeze
  NegativeInfinity = -PositiveInfinity
end
