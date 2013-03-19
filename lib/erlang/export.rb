module Erlang
  class Export
    attr_accessor :mod, :function, :arity

    def initialize(mod, function, arity)
      self.mod      = mod
      self.function = function
      self.arity    = arity
    end

    # @return [String] the nicely formatted version of the message
    def inspect
      "#<#{self.class.name} fun #{mod}:#{function}/#{arity}>"
    end

    def ==(other)
      self.class === other &&
      mod.to_s      == other.mod.to_s &&
      function.to_s == other.function.to_s &&
      arity         == other.arity
    end
  end
end