module Erlang
  # Licensing
  # =========
  #
  # Portions taken and modified from https://github.com/hamstergem/hamster
  #
  #     Copyright (c) 2009-2014 Simon Harris
  #
  #     Permission is hereby granted, free of charge, to any person obtaining
  #     a copy of this software and associated documentation files (the
  #     "Software"), to deal in the Software without restriction, including
  #     without limitation the rights to use, copy, modify, merge, publish,
  #     distribute, sublicense, and/or sell copies of the Software, and to
  #     permit persons to whom the Software is furnished to do so, subject to
  #     the following conditions:
  #
  #     The above copyright notice and this permission notice shall be
  #     included in all copies or substantial portions of the Software.
  #
  #     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  #     EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  #     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  #     NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  #     LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  #     OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  #     WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  #
  # @private
  module Immutable
    def self.included(klass)
      klass.extend(ClassMethods)
      klass.instance_eval do
        include InstanceMethods
      end
    end

    # @private
    module ClassMethods
      def new(*args)
        super.__send__(:immutable!)
      end

      def memoize(*names)
        include MemoizeMethods unless include?(MemoizeMethods)
        names.each do |name|
          original_method = "__erlang_immutable_#{name}__"
          alias_method original_method, name
          class_eval <<-METHOD, __FILE__, __LINE__
            def #{name}
              if @__erlang_immutable_memory__.instance_variable_defined?(:@#{name})
                @__erlang_immutable_memory__.instance_variable_get(:@#{name})
              else
                @__erlang_immutable_memory__.instance_variable_set(:@#{name}, #{original_method})
              end
            end
          METHOD
        end
      end
    end

    # @private
    module MemoizeMethods
      def immutable!
        @__erlang_immutable_memory__ = Object.new
        freeze
      end
    end

    # @private
    module InstanceMethods
      def immutable!
        freeze
      end

      def immutable?
        frozen?
      end

      alias_method :__erlang_immutable_dup__, :dup
      private :__erlang_immutable_dup__

      def dup
        self
      end

      def clone
        self
      end

      protected

      def transform_unless(condition, &block)
        condition ? self : transform(&block)
      end

      def transform(&block)
        __erlang_immutable_dup__.tap { |copy| copy.instance_eval(&block) }.immutable!
      end
    end
  end
end
