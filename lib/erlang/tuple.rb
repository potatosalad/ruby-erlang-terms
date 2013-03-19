module Erlang
  class Tuple < ::Array
    def arity
      length
    end

    def inspect
      "#<#{self.class.name} {#{super[1..-2]}}>"
    end

    def pretty_inspect
      "#<#{self.class.name} #{super[0..-2]}>\n"
    end

    def pretty_print(q)
      q.group(1, '{', '}') {
        q.seplist(self) { |v|
          q.pp v
        }
      }
    end
  end
end