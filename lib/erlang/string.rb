module Erlang
  class String < ::String
    def inspect
      "#<#{self.class.name} #{super}>"
    end
  end
end