module Erlang
  class List < ::Array
    attr_writer :tail

    def improper?
      tail != []
    end

    def tail(value = nil)
      if value
        self.tail = value
        self
      else
        @tail ||= []
      end
    end

    def inspect
      "#<#{self.class.name} #{super[0..-2]} | #{tail.inspect}]>"
    end

    def pretty_inspect
      "#<#{self.class.name} #{super[0..-3]} | #{tail.inspect}]>\n"
    end
  end
end