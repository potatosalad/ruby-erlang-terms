module Erlang
  # An `Export` is an external function.  It corresponds to the `fun M:F/A` syntax from Erlang.
  #
  # ### Creating Exports
  #
  #     Erlang::Export[:erlang, :make_ref, 0]
  #     # => Erlang::Export[:erlang, :make_ref, 0]
  #
  class Export
    include Erlang::Term
    include Erlang::Immutable

    # Return the module for this `Export`
    # @return [Atom]
    attr_reader :mod

    # Return the function for this `Export`
    # @return [Atom]
    attr_reader :function

    # Return the arity for this `Export`
    # @return [Integer]
    attr_reader :arity

    class << self
      # Create a new `Export` populated with the given `mod`, `function`, and `arity`.
      # @param mod [Atom, Symbol] The module atom
      # @param function [Atom, Symbol] The function atom
      # @param arity [Integer] The arity of the function
      # @return [Export]
      # @raise [ArgumentError] if `arity` is not an `Integer`
      def [](mod, function, arity)
        return new(mod, function, arity)
      end

      # Compares `a` and `b` and returns whether they are less than,
      # equal to, or greater than each other.
      #
      # @param a [Export] The left argument
      # @param b [Export] The right argument
      # @return [-1, 0, 1]
      # @raise [ArgumentError] if `a` or `b` is not an `Export`
      def compare(a, b)
        raise ArgumentError, "'a' must be of Erlang::Export type" unless a.kind_of?(Erlang::Export)
        raise ArgumentError, "'b' must be of Erlang::Export type" unless b.kind_of?(Erlang::Export)
        c = Erlang.compare(a.mod, b.mod)
        return c if c != 0
        c = Erlang.compare(a.function, b.function)
        return c if c != 0
        c = Erlang.compare(a.arity, b.arity)
        return c
      end
    end

    # @private
    def initialize(mod, function, arity)
      raise ArgumentError, 'arity must be a non-negative Integer' if not arity.is_a?(::Integer) or arity < 0
      @mod = Erlang::Atom[mod]
      @function = Erlang::Atom[function]
      @arity = arity.freeze
    end

    # Return true if `other` has the same type and contents as this `Export`.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean]
    def eql?(other)
      return true if other.equal?(self)
      if instance_of?(other.class)
        return !!(mod == other.mod &&
          function == other.function &&
          arity == other.arity)
      else
        return !!(Erlang.compare(other, self) == 0)
      end
    end
    alias :== :eql?

    # Return the contents of this `Export` as a Erlang-readable `::String`.
    #
    # @example
    #     Erlang::Export[:erlang, :make_ref, 0].erlang_inspect
    #     # => "fun 'erlang':'make_ref'/0"
    #
    # @return [::String]
    def erlang_inspect(raw = false)
      result = 'fun '
      result << Erlang.inspect(@mod, raw: raw)
      result << ':'
      result << Erlang.inspect(@function, raw: raw)
      result << '/'
      result << Erlang.inspect(@arity, raw: raw)
      return result
    end

    # @return [::String] the nicely formatted version of the `Export`.
    def inspect
      return "Erlang::Export[#{mod.inspect}, #{function.inspect}, #{arity.inspect}]"
    end

    # @private
    def hash
      state = [@mod, @function, @arity]
      return state.reduce(Erlang::Export.hash) { |acc, item| (acc << 5) - acc + item.hash }
    end

    # @return [::Array]
    # @private
    def marshal_dump
      return [@mod, @function, @arity]
    end

    # @private
    def marshal_load(args)
      mod, function, arity = args
      initialize(mod, function, arity)
      __send__(:immutable!)
      return self
    end
  end
end
