module Erlang
  class List < ::Array
    attr_writer :tail

    def improper?
      tail != []
    end

    def tail
      @tail ||= []
    end

    def inspect
      "#<#{self.class.name} #{super[0..-2]} | #{tail.inspect}]>"
    end

    def pretty_inspect
      "#<#{self.class.name} #{super[0..-3]} | #{tail.inspect}]>\n"
    end
  end
end