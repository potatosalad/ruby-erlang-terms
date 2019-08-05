module Erlang
  # An `Atom` is a literal constant with a name.
  #
  # Symbols, Booleans (`true` and `false`), and `nil` are considered `Atom`s in Ruby.
  #
  # ### Creating Atoms
  #
  #     Erlang::Atom["test"]
  #     # => :test
  #     Erlang::Atom[:Ω]
  #     # => :Ω
  #     Erlang::Atom[:Ω, utf8: true]
  #     # => Erlang::Atom["Ω", utf8: true]
  #     Erlang::Atom[true]
  #     # => true
  #     Erlang::Atom[false]
  #     # => false
  #     Erlang::Atom[nil]
  #     # => nil
  #
  #
  class Atom
    include Erlang::Term
    include Erlang::Immutable

    # Return the data for this `Atom`
    # @return [::String]
    attr_reader :data

    # Return the utf8 flag for this `Atom`
    # @return [::Boolean]
    attr_reader :utf8

    class << self
      # Create a new `Atom` populated with the given `data` and `utf8` flag.
      # @param data [::String, Symbol, ::Enumerable, Integer] The content of the `Atom`
      # @param utf8 [Boolean] Whether the `Atom` should be considered UTF-8 or not (defaults to `true`)
      # @return [Atom]
      # @raise [ArgumentError] if `data` cannot be coerced to be a `::String`
      def [](*data, utf8: true)
        return EmptyAtom if data.empty?
        if data.size == 1
          return data[0] if data[0].is_a?(Erlang::Atom)
          return FalseAtom if data[0] == false
          return NilAtom if data[0] == nil
          return TrueAtom if data[0] == true
          if data[0].is_a?(::String)
            data = data[0]
          elsif data[0].is_a?(::Symbol)
            data = data[0].to_s
          end
        end
        unless data.is_a?(::String)
          data = Erlang.iolist_to_binary(data).data
        end
        return FalseAtom if data == "false"
        return NilAtom if data == "nil"
        return TrueAtom if data == "true"
        return new(data, utf8)
      end

      # Return an empty `Atom`. If used on a subclass, returns an empty instance
      # of that class.
      #
      # @return [Atom]
      def empty
        return @empty ||= self.new
      end

      # Return a false `Atom`.
      #
      # @return [Atom]
      def false
        return @false ||= self.new("false")
      end

      # Return a nil `Atom`.
      #
      # @return [Atom]
      def nil
        return @nil ||= self.new("nil")
      end

      # Return a true `Atom`.
      #
      # @return [Atom]
      def true
        return @true ||= self.new("true")
      end

      # Compares `a` and `b` and returns whether they are less than,
      # equal to, or greater than each other.
      #
      # @param a [Atom] The left argument
      # @param b [Atom] The right argument
      # @return [-1, 0, 1]
      # @raise [ArgumentError] if `a` or `b` is not an `Atom`
      def compare(a, b)
        raise ArgumentError, "'a' must be of Erlang::Atom type" unless a.kind_of?(Erlang::Atom)
        raise ArgumentError, "'b' must be of Erlang::Atom type" unless b.kind_of?(Erlang::Atom)
        return a.data <=> b.data
      end
    end

    # @private
    def initialize(data = ::String.new.freeze, utf8 = true)
      raise ArgumentError, 'data must be a String' if not data.is_a?(::String)
      @valid_utf8, data = Erlang::Terms.utf8_encoding(data)
      @printable = Erlang::Terms.printable?(data)
      data = Erlang::Terms.binary_encoding(data) if not @printable
      @data = data.freeze
      @utf8 = !!utf8
      if @data == "false"
        @internal = false
      elsif @data == "nil"
        @internal = nil
      elsif @data == "true"
        @internal = true
      else
        @internal = @data.intern
      end
      valid_internal = false
      if @utf8 == true and @valid_utf8 and @printable
        begin
          if @internal == eval(@internal.inspect)
            valid_internal = true
          end
        rescue SyntaxError
          valid_internal = false
        end
      end
      @valid_internal = valid_internal
    end

    # @private
    def hash
      return @internal.hash
    end

    # Return true if `other` has the same type and contents as this `Atom`.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean]
    def eql?(other)
      return true if other.equal?(self)
      if instance_of?(other.class)
        return !!(@utf8 == other.utf8 && self.hash == other.hash)
      else
        return !!(Erlang.compare(other, self) == 0)
      end
    end
    alias :== :eql?

    # Returns the length of this `Atom`.
    #
    # @return [Integer]
    def length
      return @data.bytesize
    end
    alias :size :length

    # Return the contents of this `Atom` as a Erlang-readable `::String`.
    #
    # @example
    #     Erlang::Atom[:test].erlang_inspect
    #     # => "'test'"
    #     # Pass `utf8: true` for a UTF-8 version of the Atom
    #     Erlang::Atom[:Ω].erlang_inspect
    #     # => "'\\xCE\\xA9'"
    #     Erlang::Atom[:Ω, utf8: true].erlang_inspect
    #     # => "'Ω'"
    #
    # @return [::String]
    def erlang_inspect(raw = false)
      if @utf8
        result = '\''
        result << (data.inspect[1..-2].gsub('\''){"\\'"})
        result << '\''
        return result
      else
        result = '\''
        data = @valid_utf8 ? Erlang::Terms.binary_encoding(@data) : @data
        result << (data.inspect[1..-2].gsub('\''){"\\'"})
        result << '\''
        return result
      end
    end

    # @return [::String] the nicely formatted version of the `Atom`
    def inspect
      if @valid_internal
        return @internal.inspect
      elsif @utf8 == false
        return "Erlang::Atom[#{@data.inspect}, utf8: false]"
      else
        return "Erlang::Atom[#{@data.inspect}]"
      end
    end

    # @return [self] the `Atom` version of the `Atom`
    def to_atom
      return self
    end

    # @return [Binary] the `Binary` version of the `Atom`
    def to_binary
      return Erlang::Binary[@data]
    end

    # @return [List] the `List` version of the `Atom`
    def to_list
      return Erlang::List.from_enum(@data.bytes)
    end

    # @return [self] the `String` version of the `Atom`
    def to_string
      return Erlang::String[@data]
    end

    # @return [::String] the string version of the `Atom`
    def to_s
      return @data
    end
    alias :to_str :to_s

    # @return [::Array]
    # @private
    def marshal_dump
      return [@internal, @utf8]
    end

    # @private
    def marshal_load(args)
      internal, utf8 = args
      atom = self.class[internal, utf8: utf8]
      initialize(atom.data, atom.utf8)
      __send__(:immutable!)
      return self
    end
  end

  # The canonical empty `Atom`. Returned by `Atom[]` when
  # invoked with no arguments; also returned by `Atom.empty`. Prefer using this
  # one rather than creating many empty atoms using `Atom.new`.
  #
  # @private
  EmptyAtom = Erlang::Atom.empty

  # @private
  FalseAtom = Erlang::Atom.false

  # @private
  NilAtom = Erlang::Atom.nil

  # @private
  TrueAtom = Erlang::Atom.true
end
