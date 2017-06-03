module Erlang
  class ImproperListError < Erlang::Error; end
  class ProperListError < Erlang::Error; end

  # A `List` can be constructed with {List.[] List[]}.
  # It consists of a *head* (the first element) and a *tail* (which itself is also
  # a `List`, containing all the remaining elements).
  #
  # This is a singly linked list. Prepending to the list with {Erlang::List#add} runs
  # in constant time. Traversing the list from front to back is efficient,
  # however, indexed access runs in linear time because the list needs to be
  # traversed to find the element.
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
  module List
    include Erlang::Enumerable

    # @private
    CADR = /^c([ad]+)r$/

    # Create a new `List` populated with the given items.
    #
    # @example
    #   list = Erlang::List[:a, :b, :c]
    #   # => Erlang::List[:a, :b, :c]
    #
    # @return [List]
    def self.[](*items)
      return from_enum(items)
    end

    # Return an empty `Erlang::List`.
    #
    # @return [Erlang::List]
    def self.empty
      return Erlang::Nil
    end

    # This method exists distinct from `.[]` since it is ~30% faster
    # than splatting the argument.
    #
    # Marking as private only because it was introduced for an internal
    # refactoring. It could potentially be made public with a good name.
    #
    # @private
    def self.from_enum(items)
      # use destructive operations to build up a new list, like Common Lisp's NCONC
      # this is a very fast way to build up a linked list
      items = [items] if not items.kind_of?(::Enumerable)
      out = tail = Erlang::Cons.allocate
      items.each do |item|
        item = Erlang.from(item)
        new_node = Erlang::Cons.allocate
        new_node.instance_variable_set(:@head, item)
        new_node.instance_variable_set(:@improper, false)
        tail.instance_variable_set(:@tail, new_node)
        tail.instance_variable_set(:@improper, false)
        tail.immutable!
        tail = new_node
      end
      unless tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      return out.tail
    end

    def self.compare(a, b)
      return Erlang::String.compare(a, b) if a.kind_of?(Erlang::String) and b.kind_of?(Erlang::String)
      a = a.to_list if a.kind_of?(Erlang::String)
      b = b.to_list if b.kind_of?(Erlang::String)
      raise ArgumentError, "'a' must be of Erlang::List type" if not a.kind_of?(Erlang::List)
      raise ArgumentError, "'b' must be of Erlang::List type" if not b.kind_of?(Erlang::List)
      c = 0
      while c == 0 and a.kind_of?(Erlang::List) and b.kind_of?(Erlang::List) and not a.empty? and not b.empty?
        c = Erlang.compare(a.head, b.head)
        a = a.tail
        b = b.tail
      end
      if c == 0
        if not a.kind_of?(Erlang::List) or not b.kind_of?(Erlang::List)
          c = Erlang.compare(a, b)
        elsif a.empty? and not b.empty?
          c = -1
        elsif not a.empty? and b.empty?
          c = 1
        end
      end
      return c
    end

    # Create a new `List` with `item` added at the front. This is a constant
    # time operation.
    #
    # @example
    #   Erlang::List[:b, :c].add(:a)
    #   # => Erlang::List[:a, :b, :c]
    #
    # @param item [Object] The item to add
    # @return [List]
    def add(item)
      return Erlang::Cons.new(item, self)
    end
    alias :cons :add

    # Create a new `List` with `item` added at the end. This is much less efficient
    # than adding items at the front.
    #
    # @example
    #   Erlang::List[:a, :b] << :c
    #   # => Erlang::List[:a, :b, :c]
    #
    # @param item [Object] The item to add
    # @return [List]
    def <<(item)
      raise Erlang::ImproperListError if improper?
      return append(Erlang::List[item])
    end

    # Call the given block once for each item in the list, passing each
    # item from first to last successively to the block. If no block is given,
    # returns an `Enumerator`.
    #
    # @return [self]
    # @yield [item]
    def each
      raise Erlang::ImproperListError if improper?
      return to_enum unless block_given?
      list = self
      until list.empty?
        yield(list.head)
        list = list.tail
      end
      return self
    end

    # Return a `List` in which each element is derived from the corresponding
    # element in this `List`, transformed through the given block. If no block
    # is given, returns an `Enumerator`.
    #
    # @example
    #   Erlang::List[3, 2, 1].map { |e| e * e } # => Erlang::List[9, 4, 1]
    #
    # @return [List, Enumerator]
    # @yield [item]
    def map(&block)
      raise Erlang::ImproperListError if improper?
      return enum_for(:map) unless block_given?
      return self if empty?
      out = tail = Erlang::Cons.allocate
      list = self
      until list.empty?
        new_node = Erlang::Cons.allocate
        new_node.instance_variable_set(:@head, Erlang.from(yield(list.head)))
        new_node.instance_variable_set(:@improper, false)
        tail.instance_variable_set(:@tail, new_node)
        tail.instance_variable_set(:@improper, false)
        tail.immutable!
        tail = new_node
        list = list.tail
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      return out.tail
    end
    alias :collect :map

    # Return a `List` which is realized by transforming each item into a `List`,
    # and flattening the resulting lists.
    #
    # @example
    #   Erlang::List[1, 2, 3].flat_map { |x| Erlang::List[x, 100] }
    #   # => Erlang::List[1, 100, 2, 100, 3, 100]
    #
    # @return [List]
    def flat_map(&block)
      raise Erlang::ImproperListError if improper?
      return enum_for(:flat_map) unless block_given?
      return self if empty?
      out = tail = Erlang::Cons.allocate
      list = self
      until list.empty?
        head_list = Erlang::List.from_enum(yield(list.head))
        if head_list.empty?
          list = list.tail
        elsif list.tail.empty?
          tail.instance_variable_set(:@head, head_list.head)
          tail.instance_variable_set(:@tail, head_list.tail)
          tail.immutable!
          list = list.tail
        else
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@improper, false)
          tail.instance_variable_set(:@head, head_list.head)
          tail.instance_variable_set(:@tail, head_list.tail + new_node)
          tail.immutable!
          list = list.tail
          tail = new_node
        end
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      if out === tail and not out.tail.kind_of?(Erlang::List)
        return out.tail
      else
        return out
      end
    end

    # Return a `List` which contains all the items for which the given block
    # returns true.
    #
    # @example
    #   Erlang::List["Bird", "Cow", "Elephant"].select { |e| e.size >= 4 }
    #   # => Erlang::List["Bird", "Elephant"]
    #
    # @return [List]
    # @yield [item] Once for each item.
    def select(&block)
      raise Erlang::ImproperListError if improper?
      return enum_for(:select) unless block_given?
      out = tail = Erlang::Cons.allocate
      list = self
      while !list.empty?
        if yield(list.head)
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@head, list.head)
          new_node.instance_variable_set(:@improper, false)
          tail.instance_variable_set(:@tail, new_node)
          tail.instance_variable_set(:@improper, false)
          tail.immutable!
          tail = new_node
          list = list.tail
        else
          list = list.tail
        end
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      return out.tail
    end
    alias :find_all :select
    alias :keep_if  :select

    # Return a `List` which contains all elements up to, but not including, the
    # first element for which the block returns `nil` or `false`.
    #
    # @example
    #   Erlang::List[1, 3, 5, 7, 6, 4, 2].take_while { |e| e < 5 }
    #   # => Erlang::List[1, 3]
    #
    # @return [List, Enumerator]
    # @yield [item]
    def take_while(&block)
      raise Erlang::ImproperListError if improper?
      return enum_for(:take_while) unless block_given?
      return self if empty?
      out = tail = Erlang::Cons.allocate
      list = self
      while !list.empty? && yield(list.head)
        new_node = Erlang::Cons.allocate
        new_node.instance_variable_set(:@head, list.head)
        new_node.instance_variable_set(:@improper, false)
        tail.instance_variable_set(:@tail, new_node)
        tail.instance_variable_set(:@improper, false)
        tail.immutable!
        tail = new_node
        list = list.tail
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      return out.tail
    end

    # Return a `List` which contains all elements starting from the
    # first element for which the block returns `nil` or `false`.
    #
    # @example
    #   Erlang::List[1, 3, 5, 7, 6, 4, 2].drop_while { |e| e < 5 }
    #   # => Erlang::List[5, 7, 6, 4, 2]
    #
    # @return [List, Enumerator]
    # @yield [item]
    def drop_while(&block)
      raise Erlang::ImproperListError if improper?
      return enum_for(:drop_while) unless block_given?
      list = self
      list = list.tail while !list.empty? && yield(list.head)
      return list
    end

    # Return a `List` containing the first `number` items from this `List`.
    #
    # @example
    #   Erlang::List[1, 3, 5, 7, 6, 4, 2].take(3)
    #   # => Erlang::List[1, 3, 5]
    #
    # @param number [Integer] The number of items to retain
    # @return [List]
    def take(number)
      raise Erlang::ImproperListError if improper?
      return self if empty?
      return Erlang::Nil if number <= 0
      out = tail = Erlang::Cons.allocate
      list = self
      while !list.empty? && number > 0
        new_node = Erlang::Cons.allocate
        new_node.instance_variable_set(:@head, list.head)
        new_node.instance_variable_set(:@improper, false)
        tail.instance_variable_set(:@tail, new_node)
        tail.instance_variable_set(:@improper, false)
        tail.immutable!
        tail = new_node
        list = list.tail
        number -= 1
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      return out.tail
    end

    # Return a `List` containing all but the last item from this `List`.
    #
    # @example
    #   Erlang::List["A", "B", "C"].pop  # => Erlang::List["A", "B"]
    #
    # @return [List]
    def pop
      raise Erlang::ImproperListError if improper?
      return self if empty?
      new_size = size - 1
      return Erlang::List.new(head, tail.take(new_size - 1)) if new_size >= 1
      return Erlang::Nil
    end

    # Return a `List` containing all items after the first `number` items from
    # this `List`.
    #
    # @example
    #   Erlang::List[1, 3, 5, 7, 6, 4, 2].drop(3)
    #   # => Erlang::List[7, 6, 4, 2]
    #
    # @param number [Integer] The number of items to skip over
    # @return [List]
    def drop(number)
      raise Erlang::ImproperListError if improper?
      list = self
      while !list.empty? && number > 0
        number -= 1
        list = list.tail
      end
      return list
    end

    # Return a `List` with all items from this `List`, followed by all items from
    # `other`.
    #
    # @example
    #   Erlang::List[1, 2, 3].append(Erlang::List[4, 5])
    #   # => Erlang::List[1, 2, 3, 4, 5]
    #
    # @param other [List] The list to add onto the end of this one
    # @return [List]
    def append(other)
      # raise Erlang::ImproperListError if improper?
      other = Erlang.from(other)
      return self if not improper? and Erlang.is_list(other) and other.empty?
      return other if Erlang.is_list(other) and empty?
      is_improper = Erlang.is_list(other) ? other.improper? : true
      out = tail = Erlang::Cons.allocate
      list = self
      until list.empty?
        new_node = Erlang::Cons.allocate
        new_node.instance_variable_set(:@head, list.head)
        new_node.instance_variable_set(:@improper, is_improper)
        tail.instance_variable_set(:@tail, new_node)
        tail.instance_variable_set(:@improper, is_improper)
        tail.immutable!
        tail = new_node
        if not Erlang.is_list(list.tail)
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@head, list.tail)
          new_node.instance_variable_set(:@improper, is_improper)
          tail.instance_variable_set(:@tail, new_node)
          tail.instance_variable_set(:@improper, is_improper)
          tail.immutable!
          tail = new_node
          list = Erlang::Nil
        else
          list = list.tail
        end
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, other)
        tail.immutable!
      end
      return out.tail
    end
    alias :concat :append
    alias :+ :append

    # Return a `List` with the same items, but in reverse order.
    #
    # @example
    #   Erlang::List["A", "B", "C"].reverse # => Erlang::List["C", "B", "A"]
    #
    # @return [List]
    def reverse
      return reduce(Erlang::Nil) { |list, item| list.cons(item) }
    end

    # Combine two lists by "zipping" them together.  The corresponding elements
    # from this `List` and each of `others` (that is, the elements with the
    # same indices) will be gathered into lists.
    #
    # If `others` contains fewer elements than this list, `nil` will be used
    # for padding.
    #
    # @example
    #   Erlang::List["A", "B", "C"].zip(Erlang::List[1, 2, 3])
    #   # => Erlang::List[Erlang::List["A", 1], Erlang::List["B", 2], Erlang::List["C", 3]]
    #
    # @param others [List] The list to zip together with this one
    # @return [List]
    def zip(others)
      raise Erlang::ImproperListError if improper?
      others = Erlang.from(others)
      raise ArgumentError, "others must be of Erlang::List type" if not Erlang.is_list(others)
      return self if empty? && others.empty?
      out = tail = Erlang::Cons.allocate
      list = self
      until list.empty? or others.empty?
        new_node = Erlang::Cons.allocate
        new_node.instance_variable_set(:@head, Erlang::Cons.new(list.head, Erlang::Cons.new(others.head)))
        new_node.instance_variable_set(:@improper, false)
        tail.instance_variable_set(:@tail, new_node)
        tail.instance_variable_set(:@improper, false)
        tail.immutable!
        tail = new_node
        list = list.tail
        others = others.tail
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      return out.tail
    end

    # Gather the first element of each nested list into a new `List`, then the second
    # element of each nested list, then the third, and so on. In other words, if each
    # nested list is a "row", return a `List` of "columns" instead.
    #
    # @return [List]
    def transpose
      raise Erlang::ImproperListError if improper?
      return Erlang::Nil if empty?
      return Erlang::Nil if any? { |list| list.empty? }
      heads, tails = Erlang::Nil, Erlang::Nil
      reverse_each { |list| heads, tails = heads.cons(list.head), tails.cons(list.tail) }
      return Erlang::Cons.new(heads, tails.transpose)
    end

    # Return a new `List` with the same elements, but rotated so that the one at
    # index `count` is the first element of the new list. If `count` is positive,
    # the elements will be shifted left, and those shifted past the lowest position
    # will be moved to the end. If `count` is negative, the elements will be shifted
    # right, and those shifted past the last position will be moved to the beginning.
    #
    # @example
    #   l = Erlang::List["A", "B", "C", "D", "E", "F"]
    #   l.rotate(2)   # => Erlang::List["C", "D", "E", "F", "A", "B"]
    #   l.rotate(-1)  # => Erlang::List["F", "A", "B", "C", "D", "E"]
    #
    # @param count [Integer] The number of positions to shift items by
    # @return [List]
    # @raise [TypeError] if count is not an integer.
    def rotate(count = 1)
      raise Erlang::ImproperListError if improper?
      raise TypeError, "expected Integer" if not count.is_a?(Integer)
      return self if empty? || (count % size) == 0
      count = (count >= 0) ? count % size : (size - (~count % size) - 1)
      return drop(count).append(take(count))
    end

    # Return two `List`s, one of the first `number` items, and another with the
    # remaining.
    #
    # @example
    #   Erlang::List["a", "b", "c", "d"].split_at(2)
    #   # => Erlang::Tuple[Erlang::List["a", "b"], Erlang::List["c", "d"]]
    #
    # @param number [Integer] The index at which to split this list
    # @return [Tuple]
    def split_at(number)
      return Erlang::Tuple[take(number), drop(number)]
    end

    # Return two `List`s, one up to (but not including) the first item for which the
    # block returns `nil` or `false`, and another of all the remaining items.
    #
    # @example
    #   Erlang::List[4, 3, 5, 2, 1].span { |x| x > 2 }
    #   # => Erlang::Tuple[Erlang::List[4, 3, 5], Erlang::List[2, 1]]
    #
    # @return [Tuple]
    # @yield [item]
    def span(&block)
      raise Erlang::ImproperListError if improper?
      return [self, EmptyList].freeze unless block_given?
      left = left_tail = Erlang::Cons.allocate
      list = self
      while !list.empty?
        if yield(list.head)
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@head, list.head)
          new_node.instance_variable_set(:@improper, false)
          left_tail.instance_variable_set(:@tail, new_node)
          left_tail.instance_variable_set(:@improper, false)
          left_tail.immutable!
          left_tail = new_node
          list = list.tail
        else
          break
        end
      end
      if not left_tail.immutable?
        left_tail.instance_variable_set(:@tail, Erlang::Nil)
        left_tail.immutable!
      end
      return Erlang::Tuple[left.tail, list]
    end

    # Return two `List`s, one up to (but not including) the first item for which the
    # block returns true, and another of all the remaining items.
    #
    # @example
    #   Erlang::List[1, 3, 4, 2, 5].break { |x| x > 3 }
    #   # => [Erlang::List[1, 3], Erlang::List[4, 2, 5]]
    #
    # @return [Array]
    # @yield [item]
    def break(&block)
      raise Erlang::ImproperListError if improper?
      return span unless block_given?
      return span { |item| !yield(item) }
    end

    # Return an empty `List`. If used on a subclass, returns an empty instance
    # of that class.
    #
    # @return [List]
    def clear
      return Erlang::Nil
    end

    # Return a new `List` with the same items, but sorted.
    #
    # @overload sort
    #   Compare elements with their natural sort key (`#<=>`).
    #
    #   @example
    #     Erlang::List["Elephant", "Dog", "Lion"].sort
    #     # => Erlang::List["Dog", "Elephant", "Lion"]
    #
    # @overload sort
    #   Uses the block as a comparator to determine sorted order.
    #
    #   @yield [a, b] Any number of times with different pairs of elements.
    #   @yieldreturn [Integer] Negative if the first element should be sorted
    #                          lower, positive if the latter element, or 0 if
    #                          equal.
    #   @example
    #     Erlang::List["Elephant", "Dog", "Lion"].sort { |a,b| a.size <=> b.size }
    #     # => Erlang::List["Dog", "Lion", "Elephant"]
    #
    # @return [List]
    def sort(&comparator)
      comparator = Erlang.method(:compare) unless block_given?
      array = super(&comparator)
      return List.from_enum(array)
    end

    # Return a new `List` with the same items, but sorted. The sort order is
    # determined by mapping the items through the given block to obtain sort
    # keys, and then sorting the keys according to their natural sort order
    # (`#<=>`).
    #
    # @yield [element] Once for each element.
    # @yieldreturn a sort key object for the yielded element.
    # @example
    #   Erlang::List["Elephant", "Dog", "Lion"].sort_by { |e| e.size }
    #   # => Erlang::List["Dog", "Lion", "Elephant"]
    #
    # @return [List]
    def sort_by(&transformer)
      return sort unless block_given?
      block = ->(x) { Erlang.from(transformer.call(x)) }
      array = super(&block)
      return List.from_enum(array)
    end

    # Return a new `List` with `sep` inserted between each of the existing elements.
    #
    # @example
    #   Erlang::List["one", "two", "three"].intersperse(" ")
    #   # => Erlang::List["one", " ", "two", " ", "three"]
    #
    # @return [List]
    def intersperse(sep)
      raise Erlang::ImproperListError if improper?
      return self if tail.empty?
      sep = Erlang.from(sep)
      out = tail = Erlang::Cons.allocate
      list = self
      until list.empty?
        new_node = Erlang::Cons.allocate
        new_node.instance_variable_set(:@head, list.head)
        new_node.instance_variable_set(:@improper, false)
        if not list.tail.empty?
          sep_node = Erlang::Cons.allocate
          sep_node.instance_variable_set(:@head, sep)
          sep_node.instance_variable_set(:@improper, false)
          new_node.instance_variable_set(:@tail, sep_node)
          new_node.immutable!
        end
        tail.instance_variable_set(:@tail, new_node)
        tail.instance_variable_set(:@improper, false)
        tail.immutable!
        if list.tail.empty?
          tail = new_node
        else
          tail = new_node.tail
        end
        list = list.tail
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      return out.tail
    end

    # Return a `List` with the same items, but all duplicates removed.
    # Use `#hash` and `#eql?` to determine which items are duplicates.
    #
    # @example
    #   Erlang::List[:a, :b, :a, :c, :b].uniq      # => Erlang::List[:a, :b, :c]
    #   Erlang::List["a", "A", "b"].uniq(&:upcase) # => Erlang::List["a", "b"]
    #
    # @return [List]
    def uniq(&block)
      return _uniq(::Set.new, &block)
    end

    # @private
    # Separate from `uniq` so as not to expose `items` in the public API.
    def _uniq(items, &block)
      if block_given?
        out = tail = Erlang::Cons.allocate
        list = self
        while !list.empty?
          if items.add?(block.call(list.head))
            new_node = Erlang::Cons.allocate
            new_node.instance_variable_set(:@head, list.head)
            new_node.instance_variable_set(:@improper, false)
            tail.instance_variable_set(:@tail, new_node)
            tail.instance_variable_set(:@improper, false)
            tail.immutable!
            tail = new_node
            list = list.tail
          else
            list = list.tail
          end
        end
        if not tail.immutable?
          tail.instance_variable_set(:@tail, Erlang::Nil)
          tail.immutable!
        end
        return out.tail
      else
        out = tail = Erlang::Cons.allocate
        list = self
        while !list.empty?
          if items.add?(list.head)
            new_node = Erlang::Cons.allocate
            new_node.instance_variable_set(:@head, list.head)
            new_node.instance_variable_set(:@improper, false)
            tail.instance_variable_set(:@tail, new_node)
            tail.instance_variable_set(:@improper, false)
            tail.immutable!
            tail = new_node
            list = list.tail
          else
            list = list.tail
          end
        end
        if not tail.immutable?
          tail.instance_variable_set(:@tail, Erlang::Nil)
          tail.immutable!
        end
        return out.tail
      end
    end
    protected :_uniq

    # Return a `List` with all the elements from both this list and `other`,
    # with all duplicates removed.
    #
    # @example
    #   Erlang::List[1, 2].union(Erlang::List[2, 3]) # => Erlang::List[1, 2, 3]
    #
    # @param other [List] The list to merge with
    # @return [List]
    def union(other)
      raise Erlang::ImproperListError if improper?
      other = Erlang.from(other)
      raise ArgumentError, "other must be of Erlang::List type" if not Erlang.is_list(other)
      raise Erlang::ImproperListError if other.improper?
      items = ::Set.new
      return _uniq(items).append(other._uniq(items))
    end
    alias :| :union

    # Return a `List` with all elements except the last one.
    #
    # @example
    #   Erlang::List["a", "b", "c"].init # => Erlang::List["a", "b"]
    #
    # @return [List]
    def init
      raise Erlang::ImproperListError if improper?
      return Erlang::Nil if tail.empty?
      out = tail = Erlang::Cons.allocate
      list = self
      until list.tail.empty?
        new_node = Erlang::Cons.allocate
        new_node.instance_variable_set(:@head, list.head)
        new_node.instance_variable_set(:@improper, false)
        tail.instance_variable_set(:@tail, new_node)
        tail.instance_variable_set(:@improper, false)
        tail.immutable!
        tail = new_node
        list = list.tail
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      return out.tail
    end

    # Return the last item in this list.
    # @return [Object]
    def last(allow_improper = false)
      if allow_improper and improper?
        list = self
        list = list.tail while list.tail.kind_of?(Erlang::List)
        return list.tail
      else
        raise Erlang::ImproperListError if improper?
        list = self
        list = list.tail until list.tail.empty?
        return list.head
      end
    end

    # Return a `List` of all suffixes of this list.
    #
    # @example
    #   Erlang::List[1,2,3].tails
    #   # => Erlang::List[
    #   #      Erlang::List[1, 2, 3],
    #   #      Erlang::List[2, 3],
    #   #      Erlang::List[3]]
    #
    # @return [List]
    def tails
      raise Erlang::ImproperListError if improper?
      return self if empty?
      out = tail = Erlang::Cons.allocate
      list = self
      until list.empty?
        new_node = Erlang::Cons.allocate
        new_node.instance_variable_set(:@head, list)
        new_node.instance_variable_set(:@improper, false)
        tail.instance_variable_set(:@tail, new_node)
        list = list.tail
        tail = new_node
      end
      tail.instance_variable_set(:@tail, Erlang::Nil)
      return out.tail
    end

    # Return a `List` of all prefixes of this list.
    #
    # @example
    #   Erlang::List[1,2,3].inits
    #   # => Erlang::List[
    #   #      Erlang::List[1],
    #   #      Erlang::List[1, 2],
    #   #      Erlang::List[1, 2, 3]]
    #
    # @return [List]
    def inits
      raise Erlang::ImproperListError if improper?
      return self if empty?
      prev = nil
      return map do |head|
        if prev.nil?
          Erlang::List.from_enum(prev = [head])
        else
          Erlang::List.from_enum(prev.push(head))
        end
      end
    end

    # Return a `List` of all combinations of length `n` of items from this `List`.
    #
    # @example
    #   Erlang::List[1,2,3].combination(2)
    #   # => Erlang::List[
    #   #      Erlang::List[1, 2],
    #   #      Erlang::List[1, 3],
    #   #      Erlang::List[2, 3]]
    #
    # @return [List]
    def combination(n)
      raise Erlang::ImproperListError if improper?
      return Erlang::Cons.new(Erlang::Nil) if n == 0
      return self if empty?
      return tail.combination(n - 1).map { |list| list.cons(head) }.append(tail.combination(n))
    end

    # Split the items in this list in groups of `number`. Return a list of lists.
    #
    # @example
    #   ("a".."o").to_list.chunk(5)
    #   # => Erlang::List[
    #   #      Erlang::List["a", "b", "c", "d", "e"],
    #   #      Erlang::List["f", "g", "h", "i", "j"],
    #   #      Erlang::List["k", "l", "m", "n", "o"]]
    #
    # @return [List]
    def chunk(number)
      raise Erlang::ImproperListError if improper?
      return self if empty?
      out = tail = Erlang::Cons.allocate
      list = self
      until list.empty?
        first, list = list.split_at(number)
        new_node = Erlang::Cons.allocate
        new_node.instance_variable_set(:@head, first)
        new_node.instance_variable_set(:@improper, false)
        tail.instance_variable_set(:@tail, new_node)
        tail.instance_variable_set(:@improper, false)
        tail.immutable!
        tail = new_node
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      return out.tail
    end

    # Split the items in this list in groups of `number`, and yield each group
    # to the block (as a `List`). If no block is given, returns an
    # `Enumerator`.
    #
    # @return [self, Enumerator]
    # @yield [list] Once for each chunk.
    def each_chunk(number, &block)
      raise Erlang::ImproperListError if improper?
      return enum_for(:each_chunk, number) unless block_given?
      chunk(number).each(&block)
      return self
    end
    alias :each_slice :each_chunk

    # Return a new `List` with all nested lists recursively "flattened out",
    # that is, their elements inserted into the new `List` in the place where
    # the nested list originally was.
    #
    # @example
    #   Erlang::List[Erlang::List[1, 2], Erlang::List[3, 4]].flatten
    #   # => Erlang::List[1, 2, 3, 4]
    #
    # @return [List]
    def flatten
      raise Erlang::ImproperListError if improper?
      return self if empty?
      out = tail = Erlang::Cons.allocate
      list = self
      until list.empty?
        if list.head.is_a?(Erlang::Cons)
          list = list.head.append(list.tail)
        elsif Erlang::Nil.equal?(list.head)
          list = list.tail
        else
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@head, list.head)
          new_node.instance_variable_set(:@improper, false)
          tail.instance_variable_set(:@tail, new_node)
          tail.immutable!
          list = list.tail
          tail = new_node
        end
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      return out.tail
    end

    # Passes each item to the block, and gathers them into a {Map} where the
    # keys are return values from the block, and the values are `List`s of items
    # for which the block returned that value.
    #
    # @return [Map]
    # @yield [item]
    # @example
    #    Erlang::List["a", "b", "ab"].group_by { |e| e.size }
    #    # Erlang::Map[
    #    #   1 => Erlang::List["b", "a"],
    #    #   2 => Erlang::List["ab"]
    #    # ]
    def group_by(&block)
      return group_by_with(Erlang::Nil, &block)
    end
    alias :group :group_by

    # Retrieve the item at `index`. Negative indices count back from the end of
    # the list (-1 is the last item). If `index` is invalid (either too high or
    # too low), return `nil`.
    #
    # @param index [Integer] The index to retrieve
    # @return [Object]
    def at(index)
      raise Erlang::ImproperListError if improper?
      index += size if index < 0
      return nil if index < 0
      node = self
      while index > 0
        node = node.tail
        index -= 1
      end
      return node.head
    end

    # Return specific objects from the `List`. All overloads return `nil` if
    # the starting index is out of range.
    #
    # @overload list.slice(index)
    #   Returns a single object at the given `index`. If `index` is negative,
    #   count backwards from the end.
    #
    #   @param index [Integer] The index to retrieve. May be negative.
    #   @return [Object]
    #   @example
    #     l = Erlang::List["A", "B", "C", "D", "E", "F"]
    #     l[2]  # => "C"
    #     l[-1] # => "F"
    #     l[6]  # => nil
    #
    # @overload list.slice(index, length)
    #   Return a sublist starting at `index` and continuing for `length`
    #   elements or until the end of the `List`, whichever occurs first.
    #
    #   @param start [Integer] The index to start retrieving items from. May be
    #                          negative.
    #   @param length [Integer] The number of items to retrieve.
    #   @return [List]
    #   @example
    #     l = Erlang::List["A", "B", "C", "D", "E", "F"]
    #     l[2, 3]  # => Erlang::List["C", "D", "E"]
    #     l[-2, 3] # => Erlang::List["E", "F"]
    #     l[20, 1] # => nil
    #
    # @overload list.slice(index..end)
    #   Return a sublist starting at `index` and continuing to index
    #   `end` or the end of the `List`, whichever occurs first.
    #
    #   @param range [Range] The range of indices to retrieve.
    #   @return [Vector]
    #   @example
    #     l = Erlang::List["A", "B", "C", "D", "E", "F"]
    #     l[2..3]    # => Erlang::List["C", "D"]
    #     l[-2..100] # => Erlang::List["E", "F"]
    #     l[20..21]  # => nil
    def slice(arg, length = (missing_length = true))
      raise Erlang::ImproperListError if improper?
      if missing_length
        if arg.is_a?(Range)
          from, to = arg.begin, arg.end
          from += size if from < 0
          return nil if from < 0
          to   += size if to < 0
          to   += 1    if !arg.exclude_end?
          length = to - from
          length = 0 if length < 0
          list = self
          while from > 0
            return nil if list.empty?
            list = list.tail
            from -= 1
          end
          return list.take(length)
        else
          return at(arg)
        end
      else
        return nil if length < 0
        arg += size if arg < 0
        return nil if arg < 0
        list = self
        while arg > 0
          return nil if list.empty?
          list = list.tail
          arg -= 1
        end
        return list.take(length)
      end
    end
    alias :[] :slice

    # Return a `List` of indices of matching objects.
    #
    # @overload indices(object)
    #   Return a `List` of indices where `object` is found. Use `#==` for
    #   testing equality.
    #
    #   @example
    #     Erlang::List[1, 2, 3, 4].indices(2)
    #     # => Erlang::List[1]
    #
    # @overload indices
    #   Pass each item successively to the block. Return a list of indices
    #   where the block returns true.
    #
    #   @yield [item]
    #   @example
    #     Erlang::List[1, 2, 3, 4].indices { |e| e.even? }
    #     # => Erlang::List[1, 3]
    #
    # @return [List]
    def indices(object = Erlang::Undefined, i = 0, &block)
      raise Erlang::ImproperListError if improper?
      object = Erlang.from(object) if object != Erlang::Undefined
      return indices { |item| item == object } if not block_given?
      return Erlang::Nil if empty?
      out = tail = Erlang::Cons.allocate
      list = self
      until list.empty?
        if yield(list.head)
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@head, i)
          new_node.instance_variable_set(:@improper, false)
          tail.instance_variable_set(:@tail, new_node)
          tail.instance_variable_set(:@improper, false)
          tail.immutable!
          tail = new_node
          list = list.tail
        else
          list = list.tail
        end
        i += 1
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      return out.tail
    end

    # Merge all the nested lists into a single list, using the given comparator
    # block to determine the order which items should be shifted out of the nested
    # lists and into the output list.
    #
    # @example
    #   list_1 = Erlang::List[1, -3, -5]
    #   list_2 = Erlang::List[-2, 4, 6]
    #   Erlang::List[list_1, list_2].merge { |a,b| a.abs <=> b.abs }
    #   # => Erlang::List[1, -2, -3, 4, -5, 6]
    #
    # @return [List]
    # @yield [a, b] Pairs of items from matching indices in each list.
    # @yieldreturn [Integer] Negative if the first element should be selected
    #                        first, positive if the latter element, or zero if
    #                        either.
    def merge(&comparator)
      raise Erlang::ImproperListError if improper?
      return merge_by unless block_given?
      sorted = reject(&:empty?).sort do |a, b|
        yield(a.head, b.head)
      end
      return Erlang::Nil if sorted.empty?
      return Erlang::Cons.new(sorted.head.head, sorted.tail.cons(sorted.head.tail).merge(&comparator))
    end

    # Merge all the nested lists into a single list, using sort keys generated
    # by mapping the items in the nested lists through the given block to determine the
    # order which items should be shifted out of the nested lists and into the output
    # list. Whichever nested list's `#head` has the "lowest" sort key (according to
    # their natural order) will be the first in the merged `List`.
    #
    # @example
    #   list_1 = Erlang::List[1, -3, -5]
    #   list_2 = Erlang::List[-2, 4, 6]
    #   Erlang::List[list_1, list_2].merge_by { |x| x.abs }
    #   # => Erlang::List[1, -2, -3, 4, -5, 6]
    #
    # @return [List]
    # @yield [item] Once for each item in either list.
    # @yieldreturn [Object] A sort key for the element.
    def merge_by(&transformer)
      raise Erlang::ImproperListError if improper?
      return merge_by { |item| item } unless block_given?
      sorted = reject(&:empty?).sort_by do |list|
        yield(list.head)
      end
      return Erlang::Nil if sorted.empty?
      return Erlang::Cons.new(sorted.head.head, sorted.tail.cons(sorted.head.tail).merge_by(&transformer))
    end

    # Return a randomly chosen element from this list.
    # @return [Object]
    def sample
      return at(rand(size))
    end

    # Return a new `List` with the given items inserted before the item at `index`.
    #
    # @example
    #   Erlang::List["A", "D", "E"].insert(1, "B", "C") # => Erlang::List["A", "B", "C", "D", "E"]
    #
    # @param index [Integer] The index where the new items should go
    # @param items [Array] The items to add
    # @return [List]
    def insert(index, *items)
      raise Erlang::ImproperListError if improper?
      if index == 0
        return Erlang::List.from_enum(items).append(self)
      elsif index > 0
        out = tail = Erlang::Cons.allocate
        list = self
        while index > 0
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@head, list.head)
          new_node.instance_variable_set(:@improper, false)
          tail.instance_variable_set(:@tail, new_node)
          tail.instance_variable_set(:@improper, false)
          tail.immutable!
          tail = new_node
          list = list.tail
          index -= 1
        end
        if not tail.immutable?
          tail.instance_variable_set(:@tail, Erlang::List.from_enum(items).append(list))
          tail.immutable!
        end
        return out.tail
      else
        raise IndexError if index < -size
        return insert(index + size, *items)
      end
    end

    # Return a `List` with all elements equal to `obj` removed. `#==` is used
    # for testing equality.
    #
    # @example
    #   Erlang::List[:a, :b, :a, :a, :c].delete(:a) # => Erlang::List[:b, :c]
    #
    # @param obj [Object] The object to remove.
    # @return [List]
    def delete(obj)
      raise Erlang::ImproperListError if improper?
      obj = Erlang.from(obj)
      list = self
      list = list.tail while list.head == obj && !list.empty?
      return Erlang::Nil if list.empty?
      out = tail = Erlang::Cons.allocate
      until list.empty?
        if list.head == obj
          list = list.tail
        else
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@head, list.head)
          new_node.instance_variable_set(:@improper, false)
          tail.instance_variable_set(:@tail, new_node)
          tail.instance_variable_set(:@improper, false)
          tail.immutable!
          tail = new_node
          list = list.tail
        end
      end
      if not tail.immutable?
        tail.instance_variable_set(:@tail, Erlang::Nil)
        tail.immutable!
      end
      return out.tail
    end

    # Return a `List` containing the same items, minus the one at `index`.
    # If `index` is negative, it counts back from the end of the list.
    #
    # @example
    #   Erlang::List[1, 2, 3].delete_at(1)  # => Erlang::List[1, 3]
    #   Erlang::List[1, 2, 3].delete_at(-1) # => Erlang::List[1, 2]
    #
    # @param index [Integer] The index of the item to remove
    # @return [List]
    def delete_at(index)
      raise Erlang::ImproperListError if improper?
      if index == 0
        tail
      elsif index < 0
        index += size if index < 0
        return self if index < 0
        delete_at(index)
      else
        out = tail = Erlang::Cons.allocate
        list = self
        while index > 0
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@head, list.head)
          new_node.instance_variable_set(:@improper, false)
          tail.instance_variable_set(:@tail, new_node)
          tail.instance_variable_set(:@improper, false)
          tail.immutable!
          tail = new_node
          list = list.tail
          index -= 1
        end
        if not tail.immutable?
          tail.instance_variable_set(:@tail, list.tail)
          tail.immutable!
        end
        return out.tail
      end
    end

    # Replace a range of indexes with the given object.
    #
    # @overload fill(object)
    #   Return a new `List` of the same size, with every index set to `object`.
    #
    #   @param [Object] object Fill value.
    #   @example
    #     Erlang::List["A", "B", "C", "D", "E", "F"].fill("Z")
    #     # => Erlang::List["Z", "Z", "Z", "Z", "Z", "Z"]
    #
    # @overload fill(object, index)
    #   Return a new `List` with all indexes from `index` to the end of the
    #   vector set to `obj`.
    #
    #   @param [Object] object Fill value.
    #   @param [Integer] index Starting index. May be negative.
    #   @example
    #     Erlang::List["A", "B", "C", "D", "E", "F"].fill("Z", 3)
    #     # => Erlang::List["A", "B", "C", "Z", "Z", "Z"]
    #
    # @overload fill(object, index, length)
    #   Return a new `List` with `length` indexes, beginning from `index`,
    #   set to `obj`. Expands the `List` if `length` would extend beyond the
    #   current length.
    #
    #   @param [Object] object Fill value.
    #   @param [Integer] index Starting index. May be negative.
    #   @param [Integer] length
    #   @example
    #     Erlang::List["A", "B", "C", "D", "E", "F"].fill("Z", 3, 2)
    #     # => Erlang::List["A", "B", "C", "Z", "Z", "F"]
    #     Erlang::List["A", "B"].fill("Z", 1, 5)
    #     # => Erlang::List["A", "Z", "Z", "Z", "Z", "Z"]
    #
    # @return [List]
    # @raise [IndexError] if index is out of negative range.
    def fill(obj, index = 0, length = nil)
      raise Erlang::ImproperListError if improper?
      obj = Erlang.from(obj)
      if index == 0
        length ||= size
        if length > 0
          out = tail = Erlang::Cons.allocate
          list = self
          while length > 0
            new_node = Erlang::Cons.allocate
            new_node.instance_variable_set(:@head, obj)
            new_node.instance_variable_set(:@improper, false)
            tail.instance_variable_set(:@tail, new_node)
            tail.instance_variable_set(:@improper, false)
            tail.immutable!
            tail = new_node
            list = list.tail
            length -= 1
          end
          if not tail.immutable?
            tail.instance_variable_set(:@tail, list)
            tail.immutable!
          end
          return out.tail
        else
          self
        end
      elsif index > 0
        length ||= size - index
        length = 0 if length < 0
        out = tail = Erlang::Cons.allocate
        list = self
        while index > 0
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@head, list.head)
          new_node.instance_variable_set(:@improper, false)
          tail.instance_variable_set(:@tail, new_node)
          tail.instance_variable_set(:@improper, false)
          tail.immutable!
          tail = new_node
          list = list.tail
          index -= 1
        end
        while length > 0
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@head, obj)
          new_node.instance_variable_set(:@improper, false)
          tail.instance_variable_set(:@tail, new_node)
          tail.instance_variable_set(:@improper, false)
          tail.immutable!
          tail = new_node
          list = list.tail
          length -= 1
        end
        if not tail.immutable?
          tail.instance_variable_set(:@tail, list)
          tail.immutable!
        end
        return out.tail
      else
        raise IndexError if index < -size
        return fill(obj, index + size, length)
      end
    end

    # Yields all permutations of length `n` of the items in the list, and then
    # returns `self`. If no length `n` is specified, permutations of the entire
    # list will be yielded.
    #
    # There is no guarantee about which order the permutations will be yielded in.
    #
    # If no block is given, an `Enumerator` is returned instead.
    #
    # @example
    #   Erlang::List[1, 2, 3].permutation.to_a
    #   # => [Erlang::List[1, 2, 3],
    #   #     Erlang::List[2, 1, 3],
    #   #     Erlang::List[2, 3, 1],
    #   #     Erlang::List[1, 3, 2],
    #   #     Erlang::List[3, 1, 2],
    #   #     Erlang::List[3, 2, 1]]
    #
    # @return [self, Enumerator]
    # @yield [list] Once for each permutation.
    def permutation(length = size, &block)
      raise Erlang::ImproperListError if improper?
      return enum_for(:permutation, length) if not block_given?
      if length == 0
        yield Erlang::Nil
      elsif length == 1
        each { |obj| yield Erlang::Cons.new(obj, Erlang::Nil) }
      elsif not empty?
        if length < size
          tail.permutation(length, &block)
        end

        tail.permutation(length-1) do |p|
          0.upto(length-1) do |i|
            left,right = p.split_at(i)
            yield left.append(right.cons(head))
          end
        end
      end
      return self
    end

    # Yield every non-empty sublist to the given block. (The entire `List` also
    # counts as one sublist.)
    #
    # @example
    #   Erlang::List[1, 2, 3].subsequences { |list| p list }
    #   # prints:
    #   # Erlang::List[1]
    #   # Erlang::List[1, 2]
    #   # Erlang::List[1, 2, 3]
    #   # Erlang::List[2]
    #   # Erlang::List[2, 3]
    #   # Erlang::List[3]
    #
    # @yield [sublist] One or more contiguous elements from this list
    # @return [self]
    def subsequences(&block)
      raise Erlang::ImproperListError if improper?
      return enum_for(:subsequences) if not block_given?
      if not empty?
        1.upto(size) do |n|
          yield take(n)
        end
        tail.subsequences(&block)
      end
      return self
    end

    # Return two `List`s, the first containing all the elements for which the
    # block evaluates to true, the second containing the rest.
    #
    # @example
    #   Erlang::List[1, 2, 3, 4, 5, 6].partition { |x| x.even? }
    #   # => Erlang::Tuple[Erlang::List[2, 4, 6], Erlang::List[1, 3, 5]]
    #
    # @return [Tuple]
    # @yield [item] Once for each item.
    def partition(&block)
      raise Erlang::ImproperListError if improper?
      return enum_for(:partition) if not block_given?
      left = left_tail = Erlang::Cons.allocate
      right = right_tail = Erlang::Cons.allocate
      list = self
      while !list.empty?
        if yield(list.head)
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@head, list.head)
          new_node.instance_variable_set(:@improper, false)
          left_tail.instance_variable_set(:@tail, new_node)
          left_tail.instance_variable_set(:@improper, false)
          left_tail.immutable!
          left_tail = new_node
          list = list.tail
        else
          new_node = Erlang::Cons.allocate
          new_node.instance_variable_set(:@head, list.head)
          new_node.instance_variable_set(:@improper, false)
          right_tail.instance_variable_set(:@tail, new_node)
          right_tail.instance_variable_set(:@improper, false)
          right_tail.immutable!
          right_tail = new_node
          list = list.tail
        end
      end
      if not left_tail.immutable?
        left_tail.instance_variable_set(:@tail, Erlang::Nil)
        left_tail.immutable!
      end
      if not right_tail.immutable?
        right_tail.instance_variable_set(:@tail, Erlang::Nil)
        right_tail.immutable!
      end
      return Erlang::Tuple[left.tail, right.tail]
    end

    # Return true if `other` has the same type and contents as this `Hash`.
    #
    # @param other [Object] The collection to compare with
    # @return [Boolean]
    def eql?(other)
      return true if other.equal?(self)
      if other.kind_of?(Erlang::List)
        return false if other.kind_of?(Erlang::List) and improper? != other.improper?
        return false if not other.kind_of?(Erlang::List) and improper?
        other = Erlang::List.from_enum(other) if other.is_a?(::Array)
        return false if not other.kind_of?(Erlang::List)
        list = self
        while Erlang.is_list(list) and Erlang.is_list(other) and !list.empty? and !other.empty?
          return true if other.equal?(list)
          return other.empty? if list.empty?
          return false if other.empty?
          return false if not other.head.eql?(list.head)
          list = list.tail
          other = other.tail
        end
        return true if other.equal?(list)
        return list.eql?(other) if not Erlang.is_list(list) and not Erlang.is_list(other)
        return false if not Erlang.is_list(list) or not Erlang.is_list(other)
        return other.empty? if list.empty?
        return false
      else
        return !!(Erlang.compare(other, self) == 0)
      end
    end
    alias :== :eql?

    # See `Object#hash`
    # @return [Integer]
    def hash
      if improper?
        hash = to_proper_list.hash
        return (hash << 5) - hash + last(true).hash
      else
        hash = reduce(0) { |acc, item| (acc << 5) - acc + item.hash }
        return (hash << 5) - hash + Erlang::Nil.hash
      end
    end

    # def hash
    #   hashed = improper? ? proper.hash : reduce(0) { |hash, item| (hash << 5) - hash + item.hash }
    #   if improper?
    #     hashed = (hashed << 5) - hashed + improper_last.hash
    #   end
    #   return Erlang::List.hash ^ hashed
    # end

    # Return `self`. Since this is an immutable object duplicates are
    # equivalent.
    # @return [List]
    def dup
      return self
    end
    alias :clone :dup

    # def to_atom
    #   return Erlang::Atom[self]
    # end

    # def to_binary
    #   return Erlang::Binary[self]
    # end

    # def to_list
    #   return self
    # end

    # def to_map
    #   return Erlang::Map.from_list(self)
    # end

    # def to_string
    #   return Erlang::String[self]
    # end

    # def to_tuple
    #   return Erlang::Tuple.from_enum(self)
    # end

    # def respond_to?(name, include_private = false)
    #   super || !!name.to_s.match(CADR)
    # end

    # Return `List` with proper ending elemnet `Erlang::Nil`.
    # If the list is already proper, `self` is returned.
    # @return [List]
    def to_proper_list
      return self if not improper?
      return (self + Erlang::Nil).init
    end

    # def |(value)
    #   value = value.__erlang_term__ if not value.kind_of?(Erlang::Term)
    #   return value if empty?
    #   improper = Erlang::List.is_improper?(value)
    #   out = tail = Erlang::List.allocate
    #   list = self
    #   while Erlang::List.is_list?(list) && !list.empty?
    #     new_node = Erlang::List.allocate
    #     new_node.instance_variable_set(:@head, list.head)
    #     new_node.instance_variable_set(:@improper, improper)
    #     tail.instance_variable_set(:@tail, new_node)
    #     tail.instance_variable_set(:@improper, improper)
    #     tail.immutable!
    #     tail = new_node
    #     list = list.tail
    #   end
    #   tail.instance_variable_set(:@tail, value)
    #   tail.immutable!
    #   return out.tail
    # end

    # def improper_last(value = nil)
    #   if value.nil?
    #     raise Erlang::ProperListError if not improper?
    #     list = self
    #     list = list.tail while list.tail.is_a?(Erlang::List)
    #     return list.tail
    #   else
    #     self | value
    #   end
    # end

    # Allows this `Map` to be printed using `Erlang.inspect()`.
    #
    # @return [String]
    def erlang_inspect(raw = false)
      if improper?
        result = '['
        to_proper_list.each_with_index { |obj, i| result << ',' if i > 0; result << Erlang.inspect(obj, raw: raw) }
        result << '|'
        result << Erlang.inspect(last(true), raw: raw)
        result << ']'
        return result
      else
        result = '['
        each_with_index { |obj, i| result << ',' if i > 0; result << Erlang.inspect(obj, raw: raw) }
        result << ']'
        return result
      end
    end

    # Return the contents of this `List` as a programmer-readable `String`. If all the
    # items in the list are serializable as Ruby literal strings, the returned string can
    # be passed to `eval` to reconstitute an equivalent `List`.
    #
    # @return [::String]
    def inspect
      if improper?
        result = 'Erlang::List['
        list = to_proper_list
        list.each_with_index { |obj, i| result << ', ' if i > 0; result << obj.inspect }
        result << ']'
        result << " + #{last(true).inspect}"
        return result
      else
        result = '['
        list = self
        list.each_with_index { |obj, i| result << ', ' if i > 0; result << obj.inspect }
        result << ']'
        return result
      end
    end

    # Allows this `List` to be printed at the `pry` console, or using `pp` (from the
    # Ruby standard library), in a way which takes the amount of horizontal space on
    # the screen into account, and which indents nested structures to make them easier
    # to read.
    #
    # @private
    def pretty_print(pp)
      if improper?
        pp.group(1, 'Erlang::List[', '] + ') do
          pp.breakable ''
          pp.seplist(to_proper_list) { |obj| obj.pretty_print(pp) }
        end
        last(true).pretty_print(pp)
      else
        pp.group(1, '[', ']') do
          pp.breakable ''
          pp.seplist(self) { |obj| obj.pretty_print(pp) }
        end
      end
    end

    # @private
    def respond_to?(name, include_private = false)
      return super || !!name.to_s.match(CADR)
    end

  private
    def method_missing(name, *args, &block)
      if name.to_s.match(CADR)
        code = "def #{name}; self."
        code << Regexp.last_match[1].reverse.chars.map do |char|
          {'a' => 'head', 'd' => 'tail'}[char]
        end.join('.')
        code << '; end'
        List.class_eval(code)
        send(name, *args, &block)
      else
        super
      end
    end
  end
end
