module Erlang
  # A `Pid` is a process identifier object obtained from [`erlang:spawn/3`](http://erlang.org/doc/man/erlang.html#spawn-3).
  #
  # ### Creating Pids
  #
  #     Erlang::Pid["nonode@nohost", 38, 0, 0]
  #     # => Erlang::Pid[:"nonode@nohost", 38, 0, 0]
  #     Erlang::Pid["nonode@nohost", 38, 0, 0, new_pid: false]
  #     # => Erlang::Pid[:"nonode@nohost", 38, 0, 0, new_pid: false]
  #
  class Pid
    include Erlang::Term
    include Erlang::Immutable

    # Return the node for this `Pid`
    # @return [Atom]
    attr_reader :node

    # Return the id for this `Pid`
    # @return [Integer]
    attr_reader :id

    # Return the serial for this `Pid`
    # @return [Integer]
    attr_reader :serial

    # Return the creation for this `Pid`
    # @return [Integer]
    attr_reader :creation

    # Return true if this `Pid` is a new pid
    # @return [Boolean]
    attr_reader :new_pid

    class << self
      # Create a new `Pid` populated with the given `node`, `id`, `serial`, and `creation`.
      # @param node [Atom, Symbol] The node atom
      # @param id [Integer] The id as a non-negative integer
      # @param serial [Integer] The serial time as a non-negative integer
      # @param creation [Integer] The creation time as a non-negative integer
      # @param new_pid [Boolean] Whether the new pid format is used or not (defaults to `true`)
      # @return [Pid]
      # @raise [ArgumentError] if `node` is not an `Atom` or one of `id`, `serial`, or `creation` are not non-negative `Integer`s
      def [](node, id, serial = 0, creation = 0, new_pid: true)
        return new(node, id, serial, creation, new_pid)
      end

      # Compares `a` and `b` and returns whether they are less than,
      # equal to, or greater than each other.
      #
      # @param a [Pid] The left argument
      # @param b [Pid] The right argument
      # @return [-1, 0, 1]
      # @raise [ArgumentError] if `a` or `b` is not a `Pid`
      def compare(a, b)
        raise ArgumentError, "'a' must be of Erlang::Pid type" unless a.kind_of?(Erlang::Pid)
        raise ArgumentError, "'b' must be of Erlang::Pid type" unless b.kind_of?(Erlang::Pid)
        c = Erlang.compare(a.node, b.node)
        return c if c != 0
        c = Erlang.compare(a.id, b.id)
        return c if c != 0
        c = Erlang.compare(a.serial, b.serial)
        return c if c != 0
        c = Erlang.compare(a.creation, b.creation)
        return c
      end
    end

    # @private
    def initialize(node, id, serial = 0, creation = 0, new_pid = true)
      raise ArgumentError, 'id must be a non-negative Integer' if not id.is_a?(::Integer) or id < 0
      raise ArgumentError, 'serial must be a non-negative Integer' if not serial.is_a?(::Integer) or serial < 0
      raise ArgumentError, 'creation must be a non-negative Integer' if not creation.is_a?(::Integer) or creation < 0
      @node = Erlang::Atom[node]
      @id = id.freeze
      @serial = serial.freeze
      @creation = creation.freeze
      @new_pid = !!new_pid
    end

    # @private
    def hash
      state = [@node, @id, @serial, @creation]
      return state.reduce(Erlang::Pid.hash) { |acc, item| (acc << 5) - acc + item.hash }
    end

    # Return true if `other` has the same type and contents as this `Pid`.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean]
    def eql?(other)
      return true if other.equal?(self)
      if instance_of?(other.class)
        return !!(node == other.node &&
          id == other.id &&
          serial == other.serial &&
          creation == other.creation)
      else
        return !!(Erlang.compare(other, self) == 0)
      end
    end
    alias :== :eql?

    # Return true if this `Pid` is a new pid
    #
    # @return [Boolean]
    def new_pid?
      return @new_pid
    end

    # Return the contents of this `Pid` as a Erlang-readable `::String`.
    #
    # @example
    #     Erlang::Pid["nonode@nohost", 38, 0, 0].erlang_inspect
    #     # => "{'pid','nonode@nohost',38,0,0}"
    #     Erlang::Pid["nonode@nohost", 38, 0, 0, new_pid: false].erlang_inspect
    #     # => "{'pid','nonode@nohost',38,0,0,'false'}"
    #
    # @return [::String]
    def erlang_inspect(raw = false)
      if raw == true and Erlang.respond_to?(:term_to_binary)
        result = 'erlang:binary_to_term('
        result << Erlang.inspect(Erlang.term_to_binary(self), raw: raw)
        result << ')'
        return result
      elsif new_pid?
        return Erlang.inspect(Erlang::Tuple[:pid, node, id, serial, creation], raw: raw)
      else
        return Erlang.inspect(Erlang::Tuple[:pid, node, id, serial, creation, new_pid], raw: raw)
      end
    end

    # @return [::String] the nicely formatted version of the `Pid`.
    def inspect
      if new_pid?
        return "Erlang::Pid[#{node.inspect}, #{id.inspect}, #{serial.inspect}, #{creation.inspect}]"
      else
        return "Erlang::Pid[#{node.inspect}, #{id.inspect}, #{serial.inspect}, #{creation.inspect}, new_pid: #{new_pid.inspect}]"
      end
    end

    # @return [::Array]
    # @private
    def marshal_dump
      return [@node, @id, @serial, @creation, @new_pid]
    end

    # @private
    def marshal_load(args)
      node, id, serial, creation, new_pid = args
      initialize(node, id, serial, creation, new_pid)
      __send__(:immutable!)
      return self
    end
  end
end
