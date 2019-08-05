module Erlang
  # @private
  class NewReferenceError < Erlang::Error; end
  class NewerReferenceError < Erlang::Error; end

  # A `Reference` is an [unique reference](http://erlang.org/doc/efficiency_guide/advanced.html#unique_references).
  #
  # ### Creating New References
  #
  #     # Newer reference
  #     Erlang::Reference["nonode@nohost", 0, [0, 0, 0]]
  #     # => Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0]]
  #     # New reference
  #     Erlang::Reference["nonode@nohost", 0, [0, 0, 0], newer_reference: false]
  #     # => Erlang::Reference[:"nonode@nohost", 0, [0, 0, 0], newer_reference: false]
  #     # Old reference
  #     Erlang::Reference["nonode@nohost", 0, 0]
  #     # => Erlang::Reference[:"nonode@nohost", 0, 0]
  #
  class Reference
    include Erlang::Term
    include Erlang::Immutable

    # Return the node for this `Reference`
    # @return [Atom]
    attr_reader :node

    # Return the creation for this `Reference`
    # @return [Integer]
    attr_reader :creation

    # Return the ids for this `Reference`
    # @return [[Integer]]
    attr_reader :ids

    # Return true if this `Reference` is a newer reference
    # @return [Boolean]
    attr_reader :newer_reference

    class << self
      # Create a new `Reference` populated with the given node, creation, and id(s).
      # @param node [Atom, Symbol] The node atom
      # @param creation [Integer] The creation time as a non-negative integer
      # @param ids [Integer] The ids as a `List` of non-negative integers
      # @param newer_reference [Boolean] Whether the newer reference format is used or not (defaults to `true`)
      # @return [Reference]
      # @raise [ArgumentError] if `node` is not an `Atom` or `creation` or `ids` are not non-negative `Integer`s
      def [](node, creation, ids, newer_reference: true)
        return new(node, creation, ids, newer_reference)
      end

      # Compares `a` and `b` and returns whether they are less than,
      # equal to, or greater than each other.
      #
      # @param a [Reference] The left argument
      # @param b [Reference] The right argument
      # @return [-1, 0, 1]
      # @raise [ArgumentError] if `a` or `b` is not a `Reference`
      def compare(a, b)
        raise ArgumentError, "'a' must be of Erlang::Reference type" unless a.kind_of?(Erlang::Reference)
        raise ArgumentError, "'b' must be of Erlang::Reference type" unless b.kind_of?(Erlang::Reference)
        c = Erlang.compare(a.node, b.node)
        return c if c != 0
        c = Erlang.compare(a.creation, b.creation)
        return c if c != 0
        c = Erlang.compare(a.ids, b.ids)
        return c
      end
    end

    # @private
    def initialize(node, creation, ids, newer_reference = true)
      raise ArgumentError, 'creation must be a non-negative Integer' if not creation.is_a?(::Integer) or creation < 0
      ids = Erlang.from(ids)
      if Erlang.is_list(ids)
        raise ArgumentError, 'ids list cannot be empty' if ids.empty?
        raise ArgumentError, 'ids must be a List of non-negative Integer' if ids.any? { |id| !id.is_a?(::Integer) or id < 0 }
        @node = Erlang::Atom[node]
        @creation = creation.freeze
        @ids = ids
        @newer_reference = !!newer_reference
      else
        id = ids
        raise ArgumentError, 'id must be a non-negative Integer' if not id.is_a?(::Integer) or id < 0
        @node = Erlang::Atom[node]
        @creation = creation.freeze
        @ids = id.freeze
        @newer_reference = false
      end
    end

    # @private
    def hash
      state = [@node, @creation, @ids]
      return state.reduce(Erlang::Reference.hash) { |acc, item| (acc << 5) - acc + item.hash }
    end

    # Return true if `other` has the same type and contents as this `Reference`.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean]
    def eql?(other)
      return true if other.equal?(self)
      if instance_of?(other.class)
        return !!(@node == other.node &&
          @creation == other.creation &&
          @ids == other.ids)
      else
        return !!(Erlang.compare(other, self) == 0)
      end
    end
    alias :== :eql?

    # Return the singular id if this `Reference` is an old
    # reference.  Otherwise, raise a `NewReferenceError` or `NewerReferenceError`.
    #
    # @return [Integer]
    # @raise [NewReferenceError] if new reference
    # @raise [NewerReferenceError] if newer reference
    def id
      raise Erlang::NewerReferenceError if newer_reference?
      raise Erlang::NewReferenceError if new_reference?
      return @ids
    end

    # Return true if this is a new reference.
    #
    # @return [Boolean]
    def new_reference?
      return (Erlang.is_list(@ids) and not !!@newer_reference)
    end

    # Return true if this is a newer reference.
    #
    # @return [Boolean]
    def newer_reference?
      return (Erlang.is_list(@ids) and !!@newer_reference)
    end

    # Return the contents of this `reference` as a Erlang-readable `::String`.
    #
    # @example
    #     # Newer reference
    #     Erlang::Reference["nonode@nohost", 0, [0, 0, 0]].erlang_inspect
    #     # => "{'reference','nonode@nohost',0,[0,0,0]}"
    #     # New reference
    #     Erlang::Reference["nonode@nohost", 0, [0, 0, 0], newer_reference: false].erlang_inspect
    #     # => "{'reference','nonode@nohost',0,[0,0,0],'false'}"
    #     # Old reference
    #     Erlang::Reference["nonode@nohost", 0, 0].erlang_inspect
    #     # => "{'reference','nonode@nohost',0,0}"
    #
    # @return [::String]
    def erlang_inspect(raw = false)
      if raw == true and Erlang.respond_to?(:term_to_binary)
        result = 'erlang:binary_to_term('
        result << Erlang.inspect(Erlang.term_to_binary(self), raw: raw)
        result << ')'
        return result
      elsif newer_reference?
        return Erlang.inspect(Erlang::Tuple[:reference, @node, @creation, @ids], raw: raw)
      elsif new_reference?
        return Erlang.inspect(Erlang::Tuple[:reference, @node, @creation, @ids, @newer_reference], raw: raw)
      else
        return Erlang.inspect(Erlang::Tuple[:reference, @node, @creation, @ids], raw: raw)
      end
    end

    # @return [::String] the nicely formatted version of the `Reference`
    def inspect
      if newer_reference?
        return "Erlang::Reference[#{@node.inspect}, #{@creation.inspect}, #{@ids.inspect}]"
      elsif new_reference?
        return "Erlang::Reference[#{@node.inspect}, #{@creation.inspect}, #{@ids.inspect}, newer_reference: #{@newer_reference.inspect}]"
      else
        return "Erlang::Reference[#{@node.inspect}, #{@creation.inspect}, #{@ids.inspect}]"
      end
    end

    # @return [::Array]
    # @private
    def marshal_dump
      return [@node, @creation, @ids, @newer_reference]
    end

    # @private
    def marshal_load(args)
      node, creation, ids, newer_reference = args
      initialize(node, creation, ids, newer_reference)
      __send__(:immutable!)
      return self
    end
  end
end
