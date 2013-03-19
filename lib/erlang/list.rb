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
      "#<#{self.class.name} #{super[0..-2]}>\n"
    end

    def pretty_print(q)
      q.group(1, '[', " | #{tail.inspect}]") {
        q.seplist(self) { |v|
          q.pp v
        }
      }
    end

    def ==(other)
      if improper? and not other.respond_to?(:tail)
        false
      elsif other.respond_to?(:tail)
        super && tail == other.tail
      else
        super
      end
    end
  end
end