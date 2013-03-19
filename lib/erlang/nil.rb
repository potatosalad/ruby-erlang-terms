module Erlang
  class Nil
    def inspect
      "#<#{self.class.name} []>"
    end

    def ==(other)
      if other == []
        true
      else
        other === self.class
      end
    end
  end
end