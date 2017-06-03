module Erlang
  # An `Function` is an internal function.  It corresponds to the `fun F/A` and `fun(Arg1,...) -> ...` syntax from Erlang.
  #
  # ### Creating Functions
  #
  #     Erlang::Function[
  #       arity: 0,
  #       uniq: "c>yRz_\xF6\xED?Hv(\x04\x19\x102",
  #       index: 20,
  #       mod: :erl_eval,
  #       old_index: 20,
  #       old_uniq: 52032458,
  #       pid: Erlang::Pid["nonode@nohost", 79, 0, 0],
  #       free_vars: Erlang::List[
  #         Erlang::Tuple[
  #           Erlang::Nil,
  #           :none,
  #           :none,
  #           Erlang::List[
  #             Erlang::Tuple[
  #               :clause,
  #               27,
  #               Erlang::Nil,
  #               Erlang::Nil,
  #               Erlang::List[Erlang::Tuple[:atom, 0, :ok]]
  #             ]
  #           ]
  #         ]
  #       ]
  #     ]
  #
  class Function
    include Erlang::Term
    include Erlang::Immutable

    # Return the arity for this `Function`
    # @return [Integer]
    attr_reader :arity

    # Return the uniq for this `Function`
    # @return [Integer]
    attr_reader :uniq

    # Return the index for this `Function`
    # @return [Integer]
    attr_reader :index

    # Return the module for this `Function`
    # @return [Atom]
    attr_reader :mod

    # Return the old index for this `Function`
    # @return [Integer]
    attr_reader :old_index

    # Return the old uniq for this `Function`
    # @return [Integer]
    attr_reader :old_uniq

    # Return the pid for this `Function`
    # @return [Pid]
    attr_reader :pid

    # Return the free variables list for this `Function`
    # @return [List]
    attr_reader :free_vars

    class << self
      # Create a new `Function` populated with the given parameters.
      # @param arity [Integer] The arity of the function
      # @param uniq [::String, Integer] The uniq of the function
      # @param index [Integer] The index of the function
      # @param mod [Atom] The module atom
      # @param old_index [Integer] The old index of the function
      # @param old_uniq [Integer] The old uniq of the function
      # @param pid [Pid] The pid of the function
      # @param free_vars [List] The free variables list
      # @return [Function]
      # @raise [ArgumentError] if any of the parameters are of the wrong type or absent
      def [](mod:, free_vars:, pid: nil, arity: nil, uniq: nil, index: nil, old_index: nil, old_uniq: nil)
        return new(mod: mod, free_vars: free_vars, pid: pid, arity: arity, uniq: uniq, index: index, old_index: old_index, old_uniq: old_uniq)
      end

      # Compares `a` and `b` and returns whether they are less than,
      # equal to, or greater than each other.
      #
      # @param a [Function, Export] The left argument
      # @param b [Function, Export] The right argument
      # @return [-1, 0, 1]
      # @raise [ArgumentError] if `a` or `b` is not a `Function`
      def compare(a, b)
        return Erlang::Export.compare(a, b) if a.kind_of?(Erlang::Export) and b.kind_of?(Erlang::Export)
        return -1 if a.kind_of?(Erlang::Function) and b.kind_of?(Erlang::Export)
        return 1 if b.kind_of?(Erlang::Function) and a.kind_of?(Erlang::Export)
        raise ArgumentError, "'a' must be of Erlang::Function type" unless a.kind_of?(Erlang::Function)
        raise ArgumentError, "'b' must be of Erlang::Function type" unless b.kind_of?(Erlang::Function)
        c = Erlang.compare(a.arity, b.arity)
        return c if c != 0
        c = Erlang.compare(a.uniq, b.uniq)
        return c if c != 0
        c = Erlang.compare(a.index, b.index)
        return c if c != 0
        c = Erlang.compare(a.mod, b.mod)
        return c if c != 0
        c = Erlang.compare(a.old_index, b.old_index)
        return c if c != 0
        c = Erlang.compare(a.old_uniq, b.old_uniq)
        return c if c != 0
        c = Erlang.compare(a.pid, b.pid)
        return c if c != 0
        c = Erlang.compare(a.free_vars, b.free_vars)
        return c
      end
    end

    # @private
    def initialize(mod:, free_vars:, pid: nil, arity: nil, uniq: nil, index: nil, old_index: nil, old_uniq: nil)
      mod = Erlang::Atom[mod]
      free_vars = Erlang.from(free_vars)
      raise ArgumentError, "'free_vars' must be of Erlang::List type" if not Erlang.is_list(free_vars)
      pid ||= Erlang::Pid[:'node@host', 0, 0, 0]
      pid = Erlang.from(pid)
      raise ArgumentError, "'pid' must be of Erlang::Pid type or nil" if not Erlang.is_pid(pid)
      new_function = arity.nil? ? false : true
      if new_function
        raise ArgumentError, 'arity must be a non-negative Integer' if not arity.is_a?(::Integer) or arity < 0
        uniq ||= Digest::MD5.digest(Erlang.inspect(mod))
        uniq = ensure_unsigned_integer_128(uniq)
        index ||= 0
        old_index ||= 0
        old_uniq ||= uniq
        raise ArgumentError, 'index must be a non-negative Integer' if not Erlang.is_integer(index) or index < 0
        raise ArgumentError, 'old_index must be a non-negative Integer' if not Erlang.is_integer(old_index) or old_index < 0
        raise ArgumentError, 'old_uniq must be a non-negative Integer' if not Erlang.is_integer(old_uniq) or old_uniq < 0
        @arity = arity
        @uniq = uniq
        @index = index
        @mod = mod
        @old_index = old_index
        @old_uniq = old_uniq
        @pid = pid
        @free_vars = free_vars
      else
        uniq ||= Digest::MD5.digest(Erlang.inspect(mod))
        uniq = ensure_unsigned_integer_128(uniq)
        index ||= 0
        raise ArgumentError, 'index must be a non-negative Integer' if not Erlang.is_integer(index) or index < 0
        @pid = pid
        @mod = mod
        @index = index
        @uniq = uniq
        @free_vars = free_vars
      end
    end

    # @private
    def hash
      state = [@arity, @uniq, @index, @mod, @old_index, @old_uniq, @pid, @free_vars]
      return state.reduce(Erlang::Function.hash) { |acc, item| (acc << 5) - acc + item.hash }
    end

    # Return true if this is a new function.
    #
    # @return [Boolean]
    def new_function?
      return !!(!arity.nil?)
    end

    # Return true if `other` has the same type and contents as this `Function`.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean]
    def eql?(other)
      return true if other.equal?(self)
      if instance_of?(other.class)
        return !!(new_function? == other.new_function? &&
          arity == other.arity &&
          uniq == other.uniq &&
          index == other.index &&
          mod == other.mod &&
          old_index == other.old_index &&
          old_uniq == other.old_uniq &&
          pid == other.pid &&
          free_vars == other.free_vars)
      else
        return !!(Erlang.compare(other, self) == 0)
      end
    end
    alias :== :eql?

    # Return the contents of this `Function` as a Erlang-readable `::String`.
    #
    # @example
    #     # Using the example function at the top of this page
    #     fun.erlang_inspect
    #     # => "{'function',0,<<99,62,121,82,122,95,246,237,63,72,118,40,4,25,16,50>>,20,'erl_eval',20,52032458,{'pid','nonode@nohost',79,0,0},[{[],'none','none',[{'clause',27,[],[],[{'atom',0,'ok'}]}]}]}"
    #
    # @return [::String]
    def erlang_inspect(raw = false)
      if raw == true and Erlang.respond_to?(:term_to_binary)
        result = 'erlang:binary_to_term('
        result << Erlang.inspect(Erlang.term_to_binary(self), raw: raw)
        result << ')'
        return result
      else
        if new_function?
          return Erlang.inspect(Erlang::Tuple[:function, @arity, @uniq, @index, @mod, @old_index, @old_uniq, @pid, @free_vars], raw: raw)
        else
          return Erlang.inspect(Erlang::Tuple[:function, @pid, @mod, @index, @uniq, @free_vars], raw: raw)
        end
      end
    end

    # @return [String] the nicely formatted version of the `Function`
    def inspect
      if new_function?
        return "Erlang::Function[arity: #{arity.inspect}, uniq: #{uniq.inspect}, index: #{index.inspect}, mod: #{mod.inspect}, old_index: #{old_index.inspect}, old_uniq: #{old_uniq.inspect}, pid: #{pid.inspect}, free_vars: #{free_vars.inspect}]"
      else
        return "Erlang::Function[pid: #{pid.inspect}, mod: #{mod.inspect}, index: #{index.inspect}, uniq: #{uniq.inspect}, free_vars: #{free_vars.inspect}]"
      end
    end

    # @private
    def pretty_print(pp)
      if new_function?
        pp.group(1, 'Erlang::Function[', ']') do
          pp.breakable ''
          pp.seplist([[:arity, arity], [:uniq, uniq], [:index, index], [:mod, mod], [:old_index, old_index], [:old_uniq, old_uniq], [:pid, pid], [:free_vars, free_vars]], nil) do |key, val|
            pp.text "#{key}: "
            pp.group(1) do
              pp.breakable ''
              val.pretty_print(pp)
            end
          end
        end
      else
        pp.group(1, 'Erlang::Function[', ']') do
          pp.breakable ''
          pp.seplist([[:pid, pid], [:mod, mod], [:index, index], [:uniq, uniq], [:free_vars, free_vars]], nil) do |key, val|
            pp.text "#{key}: "
            pp.group(1) do
              pp.breakable ''
              val.pretty_print(pp)
            end
          end
        end
      end
    end

  private
    def ensure_unsigned_integer_128(uniq)
      uniq = uniq.to_s if uniq.kind_of?(Erlang::Binary) or uniq.kind_of?(Erlang::Bitstring)
      uniq = Erlang::Binary.decode_unsigned(uniq, :big) if uniq.is_a?(::String)
      raise ArgumentError, "uniq must be a non-negative Integer or a 16-byte String" if not uniq.is_a?(::Integer) or uniq < 0 or uniq > 0xffffffffffffffffffffffffffffffff
      return Erlang.from(uniq)
    end

  end
end
