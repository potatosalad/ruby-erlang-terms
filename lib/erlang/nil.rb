require 'singleton'

module Erlang
  # A list without any elements. This is a singleton, since all empty lists are equivalent.
  #
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
  class EmptyList
    include Singleton
    include Erlang::Term
    include Erlang::List
    include Erlang::Immutable

    # @private
    def hash
      return Erlang::EmptyList.hash
    end

    # There is no first item in an empty list, so return `Undefined`.
    # @return [Undefined]
    def head
      return Erlang::Undefined
    end
    alias :first :head

    # There are no subsequent elements, so return an empty list.
    # @return [self]
    def tail
      return self
    end

    def empty?
      return true
    end

    def improper?
      return false
    end

    # Return the number of items in this `List`.
    # @return [Integer]
    def size
      return 0
    end
    alias :length :size
  end

  # A list without any elements. This is a singleton, since all empty lists are equivalent.
  Nil = EmptyList.instance

  # @private
  EmptyList.freeze
end
