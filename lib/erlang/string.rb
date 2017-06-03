module Erlang
  # A `String` is a `List` of characters.
  #
  # ### Creating Strings
  #
  #     Erlang::String["test"]
  #     # => Erlang::String["test"]
  #
  # A `String` is equivalent to a `List` with `Integer` elements:
  #
  #     Erlang::String["test"] == Erlang::List[116, 101, 115, 116]
  #     # => true
  #
  class String
    include Erlang::Term
    include Erlang::Immutable

    # Return the data for this `String`
    # @return [::String]
    attr_reader :data

    class << self
      # Create a new `String` populated with the given `data`.
      # @param data [::String, Symbol, ::Enumerable, Integer] The content of the `Atom`
      # @return [String]
      # @raise [ArgumentError] if `data` cannot be coerced to be a `::String`
      def [](*data)
        return EmptyString if data.empty?
        if data.size == 1
          return data[0] if data[0].kind_of?(Erlang::String)
        end
        unless data.is_a?(::String)
          data = Erlang.iolist_to_binary(data).data
        end
        return new(data)
      end

      # Return an empty `String`. If used on a subclass, returns an empty instance
      # of that class.
      #
      # @return [String]
      def empty
        return @empty ||= self.new
      end

      # Compares `a` and `b` and returns whether they are less than,
      # equal to, or greater than each other.
      #
      # @param a [String] The left argument
      # @param b [String] The right argument
      # @return [-1, 0, 1]
      # @raise [ArgumentError] if `a` or `b` is not a `String`
      def compare(a, b)
        raise ArgumentError, "'a' must be of Erlang::String type" if not a.kind_of?(Erlang::String)
        raise ArgumentError, "'b' must be of Erlang::String type" if not b.kind_of?(Erlang::String)
        c = a.size <=> b.size
        return a.data <=> b.data if c == 0
        return Erlang::List.compare(a.to_list, b.to_list)
      end
    end

    # @private
    def initialize(data = ::String.new.freeze)
      raise ArgumentError, 'data must be a String' if not data.is_a?(::String)
      data = Erlang::Terms.binary_encoding(data)
      @data = data.freeze
    end

    # @private
    def hash
      return to_list.hash
    end

    # Returns true if this `String` is empty.
    #
    # @return [Boolean]
    def empty?
      return @data.empty?
    end

    # Returns an `::Array` with the `::String` data for this `String`.
    #
    # @return [[::String]]
    def flatten
      return [@data]
    end

    # Returns the length of this `String`.
    #
    # @return [Integer]
    def length
      return @data.bytesize
    end
    alias :size :length

    # Return true if `other` has the same type and contents as this `String`.
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

    # Return the contents of this `String` as a Erlang-readable `::String`.
    #
    # @example
    #     Erlang::String["test"].erlang_inspect
    #     # => "\"test\""
    #     # Pass `raw` as `true` for the List version
    #     Erlang::String["test"].erlang_inspect(true)
    #     # => "[116,101,115,116]"
    #
    # @return [::String]
    def erlang_inspect(raw = false)
      if raw == false
        return @data.inspect
      else
        return '[' << @data.bytes.join(',') << ']'
      end
    end

    # @return [::String] the nicely formatted version of the `String`
    def inspect
      return "Erlang::String[#{@data.inspect}]"
    end

    # @return [Atom] the `Atom` version of the `String`
    def to_atom
      return Erlang::Atom[@data]
    end

    # @return [Binary] the `Binary` version of the `String`
    def to_binary
      return Erlang::Binary[@data]
    end

    # @return [List] the `List` version of the `String`
    def to_list
      return Erlang::List.from_enum(@data.bytes)
    end

    # @return [self] the `String` version of the `String`
    def to_string
      return self
    end

    # @return [::String] the string version of the `String`
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

  # The canonical empty `Erlang::String`. Returned by `Erlang::String[]` when
  # invoked with no arguments; also returned by `Erlang::String.empty`. Prefer using this
  # one rather than creating many empty strings using `Erlang::String.new`.
  #
  # @private
  EmptyString = Erlang::String.empty
end
