module Erlang
  # The basic building block for constructing lists
  #
  # A Cons, also known as a "cons cell", has a "head" and a "tail", where
  # the head is an element in the list, and the tail is a reference to the
  # rest of the list. This way a singly linked list can be constructed, with
  # each `Erlang::Cons` holding a single element and a pointer to the next
  # `Erlang::Cons`.
  #
  # The last `Erlang::Cons` instance in the chain has the {Erlang::Nil} as its tail.
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
  class Cons
    include Erlang::Term
    include Erlang::List
    include Erlang::Immutable

    attr_reader :head

    attr_reader :tail

    class << self
      def inspect
        return Erlang::List.inspect
      end

      def pretty_inspect
        return Erlang::List.pretty_inspect
      end

      def pretty_print(q)
        return Erlang::List.pretty_print(q)
      end
    end

    def initialize(head, tail = Erlang::Nil)
      @head = Erlang.from(head)
      @tail = Erlang.from(tail)
      @improper = @tail.kind_of?(Erlang::List) ? @tail.improper? : true
    end

    def empty?
      return false
    end

    def improper?
      return !!@improper
    end

    # Return the number of items in this `Erlang::List`.
    # @return [Integer]
    def size
      raise Erlang::ImproperListError if improper?
      return 0 if empty?
      size = 0
      list = self
      until list.empty?
        list = list.tail
        size += 1
      end
      return size
    end
    memoize :size
    alias :length :size

    # @return [::Array]
    # @private
    def marshal_dump
      if improper?
        return [to_proper_list.to_a, last(true)]
      else
        return [to_a, Erlang::Nil]
      end
    end

    # @private
    def marshal_load(args)
      h, t = args
      if h.size == 0
        return t
      elsif Erlang::Nil.eql?(t)
        head = h[0]
        tail = Erlang::List.from_enum(h[1..-1])
        initialize(head, tail)
        __send__(:immutable!)
        return self
      else
        head = h[0]
        tail = Erlang::List.from_enum(h[1..-1]) + t
        initialize(head, tail)
        __send__(:immutable!)
        return self
      end
    end
  end
end
