module Erlang
  class Map < ::Hash
    def inspect
      "#<#{self.class.name} \##{super}>"
    end

    def pretty_inspect
      "#<#{self.class.name} #{super[0..-2]}>\n"
    end

    def pretty_print(q)
      q.group(1, '#{', '}') {
        q.seplist(self, nil, :each_pair) { |k, v|
          q.group {
            q.pp k
            q.text ' => '
            q.group(1) {
              q.breakable ''
              q.pp v
            }
          }
        }
      }
    end

    alias_method :original_to_s, :to_s
    def to_s
      "\##{original_to_s}"
    end
  end
end