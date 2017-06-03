module Erlang
  # A `Port` is a port object obtained from [`erlang:open_port/2`](http://erlang.org/doc/man/erlang.html#open_port-2).
  #
  # ### Creating Ports
  #
  #     Erlang::Port["nonode@nohost", 100, 1]
  #     # => Erlang::Port[:"nonode@nohost", 100, 1]
  #
  class Port
    include Erlang::Term
    include Erlang::Immutable

    # Return the node for this `Port`
    # @return [Atom]
    attr_reader :node

    # Return the id for this `Port`
    # @return [Integer]
    attr_reader :id

    # Return the creation for this `Port`
    # @return [Integer]
    attr_reader :creation

    class << self
      # Create a new `Port` populated with the given `node`, `id`, and `creation`.
      # @param node [Atom, Symbol] The node atom
      # @param id [Integer] The id as a non-negative integer
      # @param creation [Integer] The creation time as a non-negative integer
      # @return [Port]
      # @raise [ArgumentError] if `node` is not an `Atom` or `id` or `creation` are not non-negative `Integer`s
      def [](node, id, creation = 0)
        return new(node, id, creation)
      end

      # Compares `a` and `b` and returns whether they are less than,
      # equal to, or greater than each other.
      #
      # @param a [Port] The left argument
      # @param b [Port] The right argument
      # @return [-1, 0, 1]
      # @raise [ArgumentError] if `a` or `b` is not a `Port`
      def compare(a, b)
        raise ArgumentError, "'a' must be of Erlang::Port type" unless a.kind_of?(Erlang::Port)
        raise ArgumentError, "'b' must be of Erlang::Port type" unless b.kind_of?(Erlang::Port)
        c = Erlang.compare(a.node, b.node)
        return c if c != 0
        c = Erlang.compare(a.id, b.id)
        return c if c != 0
        c = Erlang.compare(a.creation, b.creation)
        return c
      end
    end

    # @private
    def initialize(node, id, creation = 0)
      raise ArgumentError, 'id must be a non-negative Integer' if not id.is_a?(::Integer) or id < 0
      raise ArgumentError, 'creation must be a non-negative Integer' if not creation.is_a?(::Integer) or creation < 0
      @node = Erlang::Atom[node]
      @id = id.freeze
      @creation = creation.freeze
    end

    # @private
    def hash
      state = [@node, @id, @creation]
      return state.reduce(Erlang::Port.hash) { |acc, item| (acc << 5) - acc + item.hash }
    end

    # Return true if `other` has the same type and contents as this `Port`.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean]
    def eql?(other)
      return true if other.equal?(self)
      if instance_of?(other.class)
        return !!(node == other.node &&
          id == other.id &&
          creation == other.creation)
      else
        return !!(Erlang.compare(other, self) == 0)
      end
    end
    alias :== :eql?

    # Return the contents of this `Port` as a Erlang-readable `::String`.
    #
    # @example
    #     Erlang::Port["nonode@nohost", 100, 1].erlang_inspect
    #     # => "{'port','nonode@nohost',100,1}"
    #
    # @return [::String]
    def erlang_inspect(raw = false)
      if raw == true and Erlang.respond_to?(:term_to_binary)
        result = 'erlang:binary_to_term('
        result << Erlang.inspect(Erlang.term_to_binary(self), raw: raw)
        result << ')'
        return result
      else
        return Erlang.inspect(Erlang::Tuple[:port, node, id, creation], raw: raw)
      end
    end

    # @return [::String] the nicely formatted version of the `Port`.
    def inspect
      return "Erlang::Port[#{node.inspect}, #{id.inspect}, #{creation.inspect}]"
    end

    # @return [::Array]
    # @private
    def marshal_dump
      return [@node, @id, @creation]
    end

    # @private
    def marshal_load(args)
      node, id, creation = args
      initialize(node, id, creation)
      __send__(:immutable!)
      return self
    end
  end
end
