module Erlang
  # @private
  module Term
    class << self
      # Extends the including class with +ClassMethods+.
      #
      # @param [Class] subclass the inheriting class
      def included(base)
        super
        base.extend(ClassMethods)
        base.send(:include, ::Comparable)
      end

      private :included
    end

    module ClassMethods
    end

    def <=>(other)
      return Erlang.compare(self, other)
    end
  end
end
