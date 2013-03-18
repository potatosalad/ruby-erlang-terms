module Erlang
  class Tuple < ::Array
    def inspect
      "#<#{self.class.name} {#{super[1..-2]}}>"
    end

    def pretty_inspect
      "#<#{self.class.name} {#{super[1..-3]}}>\n"
    end
  end
end