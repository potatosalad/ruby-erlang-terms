module Erlang
  # A `Tuple` is an ordered, integer-indexed collection of objects. Like
  # Ruby's `Array`, `Tuple` indexing starts at zero and negative indexes count
  # back from the end.
  #
  # `Tuple` has a similar interface to `Array`. The main difference is methods
  # that would destructively update an `Array` (such as {#insert} or
  # {#delete_at}) instead return new `Tuple`s and leave the existing one
  # unchanged.
  #
  # ### Creating New Tuples
  #
  #     Erlang::Tuple.new([:first, :second, :third])
  #     Erlang::Tuple[1, 2, 3, 4, 5]
  #
  # ### Retrieving Elements from Tuples
  #
  #     tuple = Erlang::Tuple[1, 2, 3, 4, 5]
  #
  #     tuple[0]      # => 1
  #     tuple[-1]     # => 5
  #     tuple[0,3]    # => Erlang::Tuple[1, 2, 3]
  #     tuple[1..-1]  # => Erlang::Tuple[2, 3, 4, 5]
  #     tuple.first   # => 1
  #     tuple.last    # => 5
  #
  # ### Creating Modified Tuples
  #
  #     tuple.add(6)            # => Erlang::Tuple[1, 2, 3, 4, 5, 6]
  #     tuple.insert(1, :a, :b) # => Erlang::Tuple[1, :a, :b, 2, 3, 4, 5]
  #     tuple.delete_at(2)      # => Erlang::Tuple[1, 2, 4, 5]
  #     tuple + [6, 7]          # => Erlang::Tuple[1, 2, 3, 4, 5, 6, 7]
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
  class Tuple
    include Erlang::Term
    include Erlang::Immutable
    include Erlang::Enumerable
    include Erlang::Associable

    # @private
    BLOCK_SIZE = 32
    # @private
    INDEX_MASK = BLOCK_SIZE - 1
    # @private
    BITS_PER_LEVEL = 5

    # Return the number of elements in this `Tuple`
    # @return [Integer]
    attr_reader :size
    alias :arity :size
    alias :length :size

    class << self
      # Create a new `Tuple` populated with the given elements.
      # @return [Tuple]
      def [](*elements)
        return new(elements.freeze)
      end

      # Return an empty `Tuple`. If used on a subclass, returns an empty instance
      # of that class.
      #
      # @return [Tuple]
      def empty
        return @empty ||= self.new
      end

      # "Raw" allocation of a new `Tuple`. Used internally to create a new
      # instance quickly after building a modified trie.
      #
      # @return [Tuple]
      # @private
      def alloc(root, size, levels)
        obj = allocate
        obj.instance_variable_set(:@root, root)
        obj.instance_variable_set(:@size, size)
        obj.instance_variable_set(:@levels, levels)
        return obj
      end

      def compare(a, b)
        raise ArgumentError, "'a' must be of Erlang::Tuple type" if not a.kind_of?(Erlang::Tuple)
        raise ArgumentError, "'b' must be of Erlang::Tuple type" if not b.kind_of?(Erlang::Tuple)
        c = a.size <=> b.size
        i = 0
        while c == 0 and i < a.size and i < b.size
          c = Erlang.compare(a[i], b[i])
          i += 1
        end
        return c
      end
    end

    def initialize(elements=[].freeze)
      elements = elements.to_a.map { |element| Erlang.from(element) }
      if elements.size <= 32
        elements = elements.dup.freeze if !elements.frozen?
        @root, @size, @levels = elements, elements.size, 0
      else
        root, size, levels = elements, elements.size, 0
        while root.size > 32
          root = root.each_slice(32).to_a
          levels += 1
        end
        @root, @size, @levels = root.freeze, size, levels
      end
    end

    # Return `true` if this `Tuple` contains no elements.
    #
    # @return [Boolean]
    def empty?
      return @size == 0
    end

    # Return the first element in the `Tuple`. If the tuple is empty, return `nil`.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C"].first  # => "A"
    #
    # @return [Object]
    def first
      return get(0)
    end

    # Return the last element in the `Tuple`. If the tuple is empty, return `nil`.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C"].last  # => "C"
    #
    # @return [Object]
    def last
      return get(-1)
    end

    # Return a new `Tuple` with `element` added after the last occupied position.
    #
    # @example
    #   Erlang::Tuple[1, 2].add(99)  # => Erlang::Tuple[1, 2, 99]
    #
    # @param element [Object] The object to insert at the end of the tuple
    # @return [Tuple]
    def add(element)
      return update_root(@size, Erlang.from(element))
    end
    alias :<< :add
    alias :push :add

    # Return a new `Tuple` with a new value at the given `index`. If `index`
    # is greater than the length of the tuple, the returned tuple will be
    # padded with `nil`s to the correct size.
    #
    # @overload put(index, element)
    #   Return a new `Tuple` with the element at `index` replaced by `element`.
    #
    #   @param element [Object] The object to insert into that position
    #   @example
    #     Erlang::Tuple[1, 2, 3, 4].put(2, 99)
    #     # => Erlang::Tuple[1, 2, 99, 4]
    #     Erlang::Tuple[1, 2, 3, 4].put(-1, 99)
    #     # => Erlang::Tuple[1, 2, 3, 99]
    #     Erlang::Tuple[].put(2, 99)
    #     # => Erlang::Tuple[nil, nil, 99]
    #
    # @overload put(index)
    #   Return a new `Tuple` with the element at `index` replaced by the return
    #   value of the block.
    #
    #   @yield (existing) Once with the existing value at the given `index`.
    #   @example
    #     Erlang::Tuple[1, 2, 3, 4].put(2) { |v| v * 10 }
    #     # => Erlang::Tuple[1, 2, 30, 4]
    #
    # @param index [Integer] The index to update. May be negative.
    # @return [Tuple]
    def put(index, element = yield(get(index)))
      raise IndexError, "index #{index} outside of tuple bounds" if index < -@size
      element = Erlang.from(element)
      index += @size if index < 0
      if index > @size
        suffix = Array.new(index - @size, nil)
        suffix << element
        return replace_suffix(@size, suffix)
      else
        return update_root(index, element)
      end
    end
    alias :set :put

    # @!method update_in(*key_path, &block)
    # Return a new `Tuple` with a deeply nested value modified to the result
    # of the given code block.  When traversing the nested `Tuple`s and
    # `Hash`es, non-existing keys are created with empty `Hash` values.
    #
    # The code block receives the existing value of the deeply nested key (or
    # `nil` if it doesn't exist). This is useful for "transforming" the value
    # associated with a certain key.
    #
    # Note that the original `Tuple` and sub-`Tuple`s and sub-`Hash`es are
    # left unmodified; new data structure copies are created along the path
    # wherever needed.
    #
    # @example
    #   t = Erlang::Tuple[123, 456, 789, Erlang::Map["a" => Erlang::Tuple[5, 6, 7]]]
    #   t.update_in(3, "a", 1) { |value| value + 9 }
    #   # => Erlang::Tuple[123, 456, 789, Erlang::Map["a" => Erlang::Tuple[5, 15, 7]]]
    #
    # @param key_path [Object(s)] List of keys which form the path to the key to be modified
    # @yield [value] The previously stored value
    # @yieldreturn [Object] The new value to store
    # @return [Tuple]
    # @see Associable#update_in

    # Retrieve the element at `index`. If there is none (either the provided index
    # is too high or too low), return `nil`.
    #
    # @example
    #   t = Erlang::Tuple["A", "B", "C", "D"]
    #   t.get(2)   # => "C"
    #   t.get(-1)  # => "D"
    #   t.get(4)   # => nil
    #
    # @param index [Integer] The index to retrieve
    # @return [Object]
    def get(index)
      return nil if @size == 0
      index += @size if index < 0
      return nil if index >= @size || index < 0
      return leaf_node_for(@root, @levels * BITS_PER_LEVEL, index)[index & INDEX_MASK]
    end
    alias :at :get

    # Retrieve the value at `index` with optional default.
    #
    # @overload fetch(index)
    #   Retrieve the value at the given index, or raise an `IndexError` if not
    #   found.
    #
    #   @param index [Integer] The index to look up
    #   @raise [IndexError] if index does not exist
    #   @example
    #     t = Erlang::Tuple["A", "B", "C", "D"]
    #     t.fetch(2)       # => "C"
    #     t.fetch(-1)      # => "D"
    #     t.fetch(4)       # => IndexError: index 4 outside of tuple bounds
    #
    # @overload fetch(index) { |index| ... }
    #   Retrieve the value at the given index, or return the result of yielding
    #   the block if not found.
    #
    #   @yield Once if the index is not found.
    #   @yieldparam [Integer] index The index which does not exist
    #   @yieldreturn [Object] Default value to return
    #   @param index [Integer] The index to look up
    #   @example
    #     t = Erlang::Tuple["A", "B", "C", "D"]
    #     t.fetch(2) { |i| i * i }   # => "C"
    #     t.fetch(4) { |i| i * i }   # => 16
    #
    # @overload fetch(index, default)
    #   Retrieve the value at the given index, or return the provided `default`
    #   value if not found.
    #
    #   @param index [Integer] The index to look up
    #   @param default [Object] Object to return if the key is not found
    #   @example
    #     t = Erlang::Tuple["A", "B", "C", "D"]
    #     t.fetch(2, "Z")  # => "C"
    #     t.fetch(4, "Z")  # => "Z"
    #
    # @return [Object]
    def fetch(index, default = (missing_default = true))
      if index >= -@size && index < @size
        return get(index)
      elsif block_given?
        return Erlang.from(yield(index))
      elsif !missing_default
        return Erlang.from(default)
      else
        raise IndexError, "index #{index} outside of tuple bounds"
      end
    end

    # Return specific objects from the `Tuple`. All overloads return `nil` if
    # the starting index is out of range.
    #
    # @overload tuple.slice(index)
    #   Returns a single object at the given `index`. If `index` is negative,
    #   count backwards from the end.
    #
    #   @param index [Integer] The index to retrieve. May be negative.
    #   @return [Object]
    #   @example
    #     t = Erlang::Tuple["A", "B", "C", "D", "E", "F"]
    #     t[2]  # => "C"
    #     t[-1] # => "F"
    #     t[6]  # => nil
    #
    # @overload tuple.slice(index, length)
    #   Return a subtuple starting at `index` and continuing for `length`
    #   elements or until the end of the `Tuple`, whichever occurs first.
    #
    #   @param start [Integer] The index to start retrieving elements from. May be
    #                          negative.
    #   @param length [Integer] The number of elements to retrieve.
    #   @return [Tuple]
    #   @example
    #     t = Erlang::Tuple["A", "B", "C", "D", "E", "F"]
    #     t[2, 3]  # => Erlang::Tuple["C", "D", "E"]
    #     t[-2, 3] # => Erlang::Tuple["E", "F"]
    #     t[20, 1] # => nil
    #
    # @overload tuple.slice(index..end)
    #   Return a subtuple starting at `index` and continuing to index
    #   `end` or the end of the `Tuple`, whichever occurs first.
    #
    #   @param range [Range] The range of indices to retrieve.
    #   @return [Tuple]
    #   @example
    #     t = Erlang::Tuple["A", "B", "C", "D", "E", "F"]
    #     t[2..3]    # => Erlang::Tuple["C", "D"]
    #     t[-2..100] # => Erlang::Tuple["E", "F"]
    #     t[20..21]  # => nil
    def slice(arg, length = (missing_length = true))
      if missing_length
        if arg.is_a?(Range)
          from, to = arg.begin, arg.end
          from += @size if from < 0
          to   += @size if to < 0
          to   += 1     if !arg.exclude_end?
          length = to - from
          length = 0 if length < 0
          return subsequence(from, length)
        else
          return get(arg)
        end
      else
        arg += @size if arg < 0
        return subsequence(arg, length)
      end
    end
    alias :[] :slice

    # Return a new `Tuple` with the given values inserted before the element
    # at `index`. If `index` is greater than the current length, `nil` values
    # are added to pad the `Tuple` to the required size.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C", "D"].insert(2, "X", "Y", "Z")
    #   # => Erlang::Tuple["A", "B", "X", "Y", "Z", "C", "D"]
    #   Erlang::Tuple[].insert(2, "X", "Y", "Z")
    #   # => Erlang::Tuple[nil, nil, "X", "Y", "Z"]
    #
    # @param index [Integer] The index where the new elements should go
    # @param elements [Array] The elements to add
    # @return [Tuple]
    # @raise [IndexError] if index exceeds negative range.
    def insert(index, *elements)
      raise IndexError if index < -@size
      index += @size if index < 0

      elements = elements.map { |element| Erlang.from(element) }

      if index < @size
        suffix = flatten_suffix(@root, @levels * BITS_PER_LEVEL, index, [])
        suffix.unshift(*elements)
      elsif index == @size
        suffix = elements
      else
        suffix = Array.new(index - @size, nil).concat(elements)
        index = @size
      end

      return replace_suffix(index, suffix)
    end

    # Return a new `Tuple` with the element at `index` removed. If the given `index`
    # does not exist, return `self`.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C", "D"].delete_at(2)
    #   # => Erlang::Tuple["A", "B", "D"]
    #
    # @param index [Integer] The index to remove
    # @return [Tuple]
    def delete_at(index)
      return self if index >= @size || index < -@size
      index += @size if index < 0

      suffix = flatten_suffix(@root, @levels * BITS_PER_LEVEL, index, [])
      return replace_suffix(index, suffix.tap { |a| a.shift })
    end

    # Return a new `Tuple` with the last element removed. Return `self` if
    # empty.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C"].pop  # => Erlang::Tuple["A", "B"]
    #
    # @return [Tuple]
    def pop
      return self if @size == 0
      return replace_suffix(@size-1, [])
    end

    # Return a new `Tuple` with `object` inserted before the first element,
    # moving the other elements upwards.
    #
    # @example
    #   Erlang::Tuple["A", "B"].unshift("Z")
    #   # => Erlang::Tuple["Z", "A", "B"]
    #
    # @param object [Object] The value to prepend
    # @return [Tuple]
    def unshift(object)
      return insert(0, Erlang.from(object))
    end

    # Return a new `Tuple` with the first element removed. If empty, return
    # `self`.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C"].shift  # => Erlang::Tuple["B", "C"]
    #
    # @return [Tuple]
    def shift
      return delete_at(0)
    end

    # Call the given block once for each element in the tuple, passing each
    # element from first to last successively to the block. If no block is given,
    # an `Enumerator` is returned instead.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C"].each { |e| puts "Element: #{e}" }
    #
    #   Element: A
    #   Element: B
    #   Element: C
    #   # => Erlang::Tuple["A", "B", "C"]
    #
    # @return [self, Enumerator]
    def each(&block)
      return to_enum unless block_given?
      traverse_depth_first(@root, @levels, &block)
      return self
    end

    # Call the given block once for each element in the tuple, from last to
    # first.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C"].reverse_each { |e| puts "Element: #{e}" }
    #
    #   Element: C
    #   Element: B
    #   Element: A
    #
    # @return [self]
    def reverse_each(&block)
      return enum_for(:reverse_each) unless block_given?
      reverse_traverse_depth_first(@root, @levels, &block)
      return self
    end

    # Return a new `Tuple` containing all elements for which the given block returns
    # true.
    #
    # @example
    #   Erlang::Tuple["Bird", "Cow", "Elephant"].select { |e| e.size >= 4 }
    #   # => Erlang::Tuple["Bird", "Elephant"]
    #
    # @return [Tuple]
    # @yield [element] Once for each element.
    def select
      return enum_for(:select) unless block_given?
      return reduce(self.class.empty) { |tuple, element| yield(element) ? tuple.add(element) : tuple }
    end
    alias :find_all :select
    alias :keep_if  :select

    # Return a new `Tuple` with all elements which are equal to `obj` removed.
    # `#==` is used for checking equality.
    #
    # @example
    #   Erlang::Tuple["C", "B", "A", "B"].delete("B")  # => Erlang::Tuple["C", "A"]
    #
    # @param obj [Object] The object to remove (every occurrence)
    # @return [Tuple]
    def delete(obj)
      obj = Erlang.from(obj)
      return select { |element| element != obj }
    end

    # Invoke the given block once for each element in the tuple, and return a new
    # `Tuple` containing the values returned by the block. If no block is
    # provided, return an enumerator.
    #
    # @example
    #   Erlang::Tuple[3, 2, 1].map { |e| e * e }  # => Erlang::Tuple[9, 4, 1]
    #
    # @return [Tuple, Enumerator]
    def map
      return enum_for(:map) if not block_given?
      return self if empty?
      return self.class.new(super)
    end
    alias :collect :map

    # Return a new `Tuple` with the concatenated results of running the block once
    # for every element in this `Tuple`.
    #
    # @example
    #   Erlang::Tuple[1, 2, 3].flat_map { |x| [x, -x] }
    #   # => Erlang::Tuple[1, -1, 2, -2, 3, -3]
    #
    # @return [Tuple]
    def flat_map
      return enum_for(:flat_map) if not block_given?
      return self if empty?
      return self.class.new(super)
    end

    # Return a new `Tuple` with the same elements as this one, but randomly permuted.
    #
    # @example
    #   Erlang::Tuple[1, 2, 3, 4].shuffle  # => Erlang::Tuple[4, 1, 3, 2]
    #
    # @return [Tuple]
    def shuffle
      return self.class.new(((array = to_a).frozen? ? array.shuffle : array.shuffle!).freeze)
    end

    # Return a new `Tuple` with no duplicate elements, as determined by `#hash` and
    # `#eql?`. For each group of equivalent elements, only the first will be retained.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C", "B"].uniq      # => Erlang::Tuple["A", "B", "C"]
    #   Erlang::Tuple["a", "A", "b"].uniq(&:upcase) # => Erlang::Tuple["a", "b"]
    #
    # @return [Tuple]
    def uniq(&block)
      array = self.to_a
      if block_given?
        if array.frozen?
          return self.class.new(array.uniq(&block).freeze)
        elsif array.uniq!(&block) # returns nil if no changes were made
          return self.class.new(array.freeze)
        else
          return self
        end
      elsif array.frozen?
        return self.class.new(array.uniq.freeze)
      elsif array.uniq! # returns nil if no changes were made
        return self.class.new(array.freeze)
      else
        return self
      end
    end

    # Return a new `Tuple` with the same elements as this one, but in reverse order.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C"].reverse  # => Erlang::Tuple["C", "B", "A"]
    #
    # @return [Tuple]
    def reverse
      return self.class.new(((array = to_a).frozen? ? array.reverse : array.reverse!).freeze)
    end

    # Return a new `Tuple` with the same elements, but rotated so that the one at
    # index `count` is the first element of the new tuple. If `count` is positive,
    # the elements will be shifted left, and those shifted past the lowest position
    # will be moved to the end. If `count` is negative, the elements will be shifted
    # right, and those shifted past the last position will be moved to the beginning.
    #
    # @example
    #   t = Erlang::Tuple["A", "B", "C", "D", "E", "F"]
    #   t.rotate(2)   # => Erlang::Tuple["C", "D", "E", "F", "A", "B"]
    #   t.rotate(-1)  # => Erlang::Tuple["F", "A", "B", "C", "D", "E"]
    #
    # @param count [Integer] The number of positions to shift elements by
    # @return [Tuple]
    def rotate(count = 1)
      return self if (count % @size) == 0
      return self.class.new(((array = to_a).frozen? ? array.rotate(count) : array.rotate!(count)).freeze)
    end

    # Return a new `Tuple` with all nested tuples and arrays recursively "flattened
    # out". That is, their elements inserted into the new `Tuple` in the place where
    # the nested array/tuple originally was. If an optional `level` argument is
    # provided, the flattening will only be done recursively that number of times.
    # A `level` of 0 means not to flatten at all, 1 means to only flatten nested
    # arrays/tuples which are directly contained within this `Tuple`.
    #
    # @example
    #   t = Erlang::Tuple["A", Erlang::Tuple["B", "C", Erlang::Tuple["D"]]]
    #   t.flatten(1)
    #   # => Erlang::Tuple["A", "B", "C", Erlang::Tuple["D"]]
    #   t.flatten
    #   # => Erlang::Tuple["A", "B", "C", "D"]
    #
    # @param level [Integer] The depth to which flattening should be applied
    # @return [Tuple]
    def flatten(level = -1)
      return self if level == 0
      array = self.to_a
      if array.frozen?
        return self.class.new(array.flatten(level).freeze)
      elsif array.flatten!(level) # returns nil if no changes were made
        return self.class.new(array.freeze)
      else
        return self
      end
    end

    # Return a new `Tuple` built by concatenating this one with `other`. `other`
    # can be any object which is convertible to an `Array` using `#to_a`.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C"] + ["D", "E"]
    #   # => Erlang::Tuple["A", "B", "C", "D", "E"]
    #
    # @param other [Enumerable] The collection to concatenate onto this tuple
    # @return [Tuple]
    def +(other)
      other = Erlang.from(other)
      other = other.to_a
      other = other.dup if other.frozen?
      return replace_suffix(@size, other)
    end
    alias :concat :+

    # Combine two tuples by "zipping" them together. `others` should be arrays
    # and/or tuples. The corresponding elements from this `Tuple` and each of
    # `others` (that is, the elements with the same indices) will be gathered
    # into arrays.
    #
    # If `others` contains fewer elements than this tuple, `nil` will be used
    # for padding.
    #
    # @overload zip(*others)
    #   Return a new tuple containing the new arrays.
    #
    #   @return [Tuple]
    #
    # @overload zip(*others)
    #   @yield [pair] once for each array
    #   @return [nil]
    #
    # @example
    #   t1 = Erlang::Tuple["A", "B", "C"]
    #   t2 = Erlang::Tuple[1, 2]
    #   t1.zip(t2)
    #   # => Erlang::Tuple[["A", 1], ["B", 2], ["C", nil]]
    #
    # @param others [Array] The arrays/tuples to zip together with this one
    # @return [Tuple]
    def zip(*others)
      others = others.map { |other| Erlang.from(other) }
      if block_given?
        return super(*others)
      else
        return self.class.new(super(*others))
      end
    end

    # Return a new `Tuple` with the same elements, but sorted.
    #
    # @overload sort
    #   Compare elements with their natural sort key (`#<=>`).
    #
    #   @example
    #     Erlang::Tuple["Elephant", "Dog", "Lion"].sort
    #     # => Erlang::Tuple["Dog", "Elephant", "Lion"]
    #
    # @overload sort
    #   Uses the block as a comparator to determine sorted order.
    #
    #   @yield [a, b] Any number of times with different pairs of elements.
    #   @yieldreturn [Integer] Negative if the first element should be sorted
    #                          lower, positive if the latter element, or 0 if
    #                          equal.
    #   @example
    #     Erlang::Tuple["Elephant", "Dog", "Lion"].sort { |a,b| a.size <=> b.size }
    #     # => Erlang::Tuple["Dog", "Lion", "Elephant"]
    #
    # @return [Tuple]
    def sort(&comparator)
      comparator = Erlang.method(:compare) unless block_given?
      array = super(&comparator)
      return self.class.new(array)
    end

    # Return a new `Tuple` with the same elements, but sorted. The sort order is
    # determined by mapping the elements through the given block to obtain sort
    # keys, and then sorting the keys according to their natural sort order
    # (`#<=>`).
    #
    # @yield [element] Once for each element.
    # @yieldreturn a sort key object for the yielded element.
    # @example
    #   Erlang::Tuple["Elephant", "Dog", "Lion"].sort_by { |e| e.size }
    #   # => Erlang::Tuple["Dog", "Lion", "Elephant"]
    #
    # @return [Tuple]
    def sort_by
      return sort unless block_given?
      block = ->(x) { Erlang.from(transformer.call(x)) }
      array = super(&block)
      return self.class.new(array)
    end

    # Drop the first `n` elements and return the rest in a new `Tuple`.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C", "D", "E", "F"].drop(2)
    #   # => Erlang::Tuple["C", "D", "E", "F"]
    #
    # @param n [Integer] The number of elements to remove
    # @return [Tuple]
    # @raise ArgumentError if `n` is negative.
    def drop(n)
      return self if n == 0
      return self.class.empty if n >= @size
      raise ArgumentError, "attempt to drop negative size" if n < 0
      return self.class.new(flatten_suffix(@root, @levels * BITS_PER_LEVEL, n, []))
    end

    # Return only the first `n` elements in a new `Tuple`.
    #
    # @example
    #   Erlang::Tuple["A", "B", "C", "D", "E", "F"].take(4)
    #   # => Erlang::Tuple["A", "B", "C", "D"]
    #
    # @param n [Integer] The number of elements to retain
    # @return [Tuple]
    def take(n)
      return self if n >= @size
      return self.class.new(super)
    end

    # Drop elements up to, but not including, the first element for which the
    # block returns `nil` or `false`. Gather the remaining elements into a new
    # `Tuple`. If no block is given, an `Enumerator` is returned instead.
    #
    # @example
    #   Erlang::Tuple[1, 3, 5, 7, 6, 4, 2].drop_while { |e| e < 5 }
    #   # => Erlang::Tuple[5, 7, 6, 4, 2]
    #
    # @return [Tuple, Enumerator]
    def drop_while
      return enum_for(:drop_while) if not block_given?
      return self.class.new(super)
    end

    # Gather elements up to, but not including, the first element for which the
    # block returns `nil` or `false`, and return them in a new `Tuple`. If no block
    # is given, an `Enumerator` is returned instead.
    #
    # @example
    #   Erlang::Tuple[1, 3, 5, 7, 6, 4, 2].take_while { |e| e < 5 }
    #   # => Erlang::Tuple[1, 3]
    #
    # @return [Tuple, Enumerator]
    def take_while
      return enum_for(:take_while) if not block_given?
      return self.class.new(super)
    end

    # Repetition. Return a new `Tuple` built by concatenating `times` copies
    # of this one together.
    #
    # @example
    #   Erlang::Tuple["A", "B"] * 3
    #   # => Erlang::Tuple["A", "B", "A", "B", "A", "B"]
    #
    # @param times [Integer] The number of times to repeat the elements in this tuple
    # @return [Tuple]
    def *(times)
      return self.class.empty if times == 0
      return self if times == 1
      result = (to_a * times)
      return result.is_a?(Array) ? self.class.new(result) : result
    end

    # Replace a range of indexes with the given object.
    #
    # @overload fill(object)
    #   Return a new `Tuple` of the same size, with every index set to
    #   `object`.
    #
    #   @param [Object] object Fill value.
    #   @example
    #     Erlang::Tuple["A", "B", "C", "D", "E", "F"].fill("Z")
    #     # => Erlang::Tuple["Z", "Z", "Z", "Z", "Z", "Z"]
    #
    # @overload fill(object, index)
    #   Return a new `Tuple` with all indexes from `index` to the end of the
    #   tuple set to `object`.
    #
    #   @param [Object] object Fill value.
    #   @param [Integer] index Starting index. May be negative.
    #   @example
    #     Erlang::Tuple["A", "B", "C", "D", "E", "F"].fill("Z", 3)
    #     # => Erlang::Tuple["A", "B", "C", "Z", "Z", "Z"]
    #
    # @overload fill(object, index, length)
    #   Return a new `Tuple` with `length` indexes, beginning from `index`,
    #   set to `object`. Expands the `Tuple` if `length` would extend beyond
    #   the current length.
    #
    #   @param [Object] object Fill value.
    #   @param [Integer] index Starting index. May be negative.
    #   @param [Integer] length
    #   @example
    #     Erlang::Tuple["A", "B", "C", "D", "E", "F"].fill("Z", 3, 2)
    #     # => Erlang::Tuple["A", "B", "C", "Z", "Z", "F"]
    #     Erlang::Tuple["A", "B"].fill("Z", 1, 5)
    #     # => Erlang::Tuple["A", "Z", "Z", "Z", "Z", "Z"]
    #
    # @return [Tuple]
    # @raise [IndexError] if index is out of negative range.
    def fill(object, index = 0, length = nil)
      raise IndexError if index < -@size
      object = Erlang.from(object)
      index += @size if index < 0
      length ||= @size - index # to the end of the array, if no length given

      if index < @size
        suffix = flatten_suffix(@root, @levels * BITS_PER_LEVEL, index, [])
        suffix.fill(object, 0, length)
      elsif index == @size
        suffix = Array.new(length, object)
      else
        suffix = Array.new(index - @size, nil).concat(Array.new(length, object))
        index = @size
      end

      return replace_suffix(index, suffix)
    end

    # When invoked with a block, yields all combinations of length `n` of elements
    # from the `Tuple`, and then returns `self`. There is no guarantee about
    # which order the combinations will be yielded.
    #
    # If no block is given, an `Enumerator` is returned instead.
    #
    # @example
    #   t = Erlang::Tuple[5, 6, 7, 8]
    #   t.combination(3) { |c| puts "Combination: #{c}" }
    #
    #   Combination: [5, 6, 7]
    #   Combination: [5, 6, 8]
    #   Combination: [5, 7, 8]
    #   Combination: [6, 7, 8]
    #   #=> Erlang::Tuple[5, 6, 7, 8]
    #
    # @return [self, Enumerator]
    def combination(n)
      return enum_for(:combination, n) if not block_given?
      return self if n < 0 || @size < n
      if n == 0
        yield []
      elsif n == 1
        each { |element| yield [element] }
      elsif n == @size
        yield self.to_a
      else
        combos = lambda do |result,index,remaining|
          while @size - index > remaining
            if remaining == 1
              yield result.dup << get(index)
            else
              combos[result.dup << get(index), index+1, remaining-1]
            end
            index += 1
          end
          index.upto(@size-1) { |i| result << get(i) }
          yield result
        end
        combos[[], 0, n]
      end
      return self
    end

    # When invoked with a block, yields all repeated combinations of length `n` of
    # tuples from the `Tuple`, and then returns `self`. A "repeated combination" is
    # one in which any tuple from the `Tuple` can appear consecutively any number of
    # times.
    #
    # There is no guarantee about which order the combinations will be yielded in.
    #
    # If no block is given, an `Enumerator` is returned instead.
    #
    # @example
    #   t = Erlang::Tuple[5, 6, 7, 8]
    #   t.repeated_combination(2) { |c| puts "Combination: #{c}" }
    #
    #   Combination: [5, 5]
    #   Combination: [5, 6]
    #   Combination: [5, 7]
    #   Combination: [5, 8]
    #   Combination: [6, 6]
    #   Combination: [6, 7]
    #   Combination: [6, 8]
    #   Combination: [7, 7]
    #   Combination: [7, 8]
    #   Combination: [8, 8]
    #   # => Erlang::Tuple[5, 6, 7, 8]
    #
    # @return [self, Enumerator]
    def repeated_combination(n)
      return enum_for(:repeated_combination, n) if not block_given?
      if n < 0
        # yield nothing
      elsif n == 0
        yield []
      elsif n == 1
        each { |element| yield [element] }
      elsif @size == 0
        # yield nothing
      else
        combos = lambda do |result,index,remaining|
          while index < @size-1
            if remaining == 1
              yield result.dup << get(index)
            else
              combos[result.dup << get(index), index, remaining-1]
            end
            index += 1
          end
          element = get(index)
          remaining.times { result << element }
          yield result
        end
        combos[[], 0, n]
      end
      return self
    end

    # Yields all permutations of length `n` of elements from the `Tuple`, and then
    # returns `self`. If no length `n` is specified, permutations of all elements
    # will be yielded.
    #
    # There is no guarantee about which order the permutations will be yielded in.
    #
    # If no block is given, an `Enumerator` is returned instead.
    #
    # @example
    #   t = Erlang::Tuple[5, 6, 7]
    #   t.permutation(2) { |p| puts "Permutation: #{p}" }
    #
    #   Permutation: [5, 6]
    #   Permutation: [5, 7]
    #   Permutation: [6, 5]
    #   Permutation: [6, 7]
    #   Permutation: [7, 5]
    #   Permutation: [7, 6]
    #   # => Erlang::Tuple[5, 6, 7]
    #
    # @return [self, Enumerator]
    def permutation(n = @size)
      return enum_for(:permutation, n) if not block_given?
      if n < 0 || @size < n
        # yield nothing
      elsif n == 0
        yield []
      elsif n == 1
        each { |element| yield [element] }
      else
        used, result = [], []
        perms = lambda do |index|
          0.upto(@size-1) do |i|
            if !used[i]
              result[index] = get(i)
              if index < n-1
                used[i] = true
                perms[index+1]
                used[i] = false
              else
                yield result.dup
              end
            end
          end
        end
        perms[0]
      end
      return self
    end

    # When invoked with a block, yields all repeated permutations of length `n` of
    # elements from the `Tuple`, and then returns `self`. A "repeated permutation" is
    # one where any element from the `Tuple` can appear any number of times, and in
    # any position (not just consecutively)
    #
    # If no length `n` is specified, permutations of all elements will be yielded.
    # There is no guarantee about which order the permutations will be yielded in.
    #
    # If no block is given, an `Enumerator` is returned instead.
    #
    # @example
    #   t = Erlang::Tuple[5, 6, 7]
    #   t.repeated_permutation(2) { |p| puts "Permutation: #{p}" }
    #
    #   Permutation: [5, 5]
    #   Permutation: [5, 6]
    #   Permutation: [5, 7]
    #   Permutation: [6, 5]
    #   Permutation: [6, 6]
    #   Permutation: [6, 7]
    #   Permutation: [7, 5]
    #   Permutation: [7, 6]
    #   Permutation: [7, 7]
    #   # => Erlang::Tuple[5, 6, 7]
    #
    # @return [self, Enumerator]
    def repeated_permutation(n = @size)
      return enum_for(:repeated_permutation, n) if not block_given?
      if n < 0
        # yield nothing
      elsif n == 0
        yield []
      elsif n == 1
        each { |element| yield [element] }
      else
        result = []
        perms = lambda do |index|
          0.upto(@size-1) do |i|
            result[index] = get(i)
            if index < n-1
              perms[index+1]
            else
              yield result.dup
            end
          end
        end
        perms[0]
      end
      return self
    end

    # Cartesian product or multiplication.
    #
    # @overload product(*tuples)
    #   Return a `Tuple` of all combinations of elements from this `Tuple` and each
    #   of the given tuples or arrays. The length of the returned `Tuple` is the product
    #   of `self.size` and the size of each argument tuple or array.
    #   @example
    #     t1 = Erlang::Tuple[1, 2, 3]
    #     t2 = Erlang::Tuple["A", "B"]
    #     t1.product(t2)
    #     # => [[1, "A"], [1, "B"], [2, "A"], [2, "B"], [3, "A"], [3, "B"]]
    # @overload product
    #   Return the result of multiplying all the elements in this `Tuple` together.
    #
    #   @example
    #     Erlang::Tuple[1, 2, 3, 4, 5].product  # => 120
    #
    # @return [Tuple]
    def product(*tuples)
      tuples = tuples.map { |tuple| Erlang.from(tuple) }
      # if no tuples passed, return "product" as in result of multiplying all elements
      return super if tuples.empty?

      tuples.unshift(self)

      if tuples.any?(&:empty?)
        return block_given? ? self : []
      end

      counters = Array.new(tuples.size, 0)

      bump_counters = lambda do
        i = tuples.size-1
        counters[i] += 1
        while counters[i] == tuples[i].size
          counters[i] = 0
          i -= 1
          return true if i == -1 # we are done
          counters[i] += 1
        end
        false # not done yet
      end
      build_array = lambda do
        array = []
        counters.each_with_index { |index,i| array << tuples[i][index] }
        array
      end

      if block_given?
        while true
          yield build_array[]
          return self if bump_counters[]
        end
      else
        result = []
        while true
          result << build_array[]
          return result if bump_counters[]
        end
      end
    end

    # Assume all elements are tuples or arrays and transpose the rows and columns.
    # In other words, take the first element of each nested tuple/array and gather
    # them together into a new `Tuple`. Do likewise for the second, third, and so on
    # down to the end of each nested Tuple/array. Gather all the resulting `Tuple`s
    # into a new `Tuple` and return it.
    #
    # This operation is closely related to {#zip}. The result is almost the same as
    # calling {#zip} on the first nested Tuple/array with the others supplied as
    # arguments.
    #
    # @example
    #   Erlang::Tuple[["A", 10], ["B", 20], ["C", 30]].transpose
    #   # => Erlang::Tuple[Erlang::Tuple["A", "B", "C"], Erlang::Tuple[10, 20, 30]]
    #
    # @return [Tuple]
    # @raise [IndexError] if elements are not of the same size.
    # @raise [TypeError] if an element can not be implicitly converted to an array (using `#to_ary`)
    def transpose
      return self.class.empty if empty?
      result = Array.new(first.size) { [] }

      0.upto(@size-1) do |i|
        source = get(i)
        if source.size != result.size
          raise IndexError, "element size differs (#{source.size} should be #{result.size})"
        end

        0.upto(result.size-1) do |j|
          result[j].push(source[j])
        end
      end

      result.map! { |a| self.class.new(a) }
      return self.class.new(result)
    end

    # Finds a value from this `Tuple` which meets the condition defined by the
    # provided block, using a binary search. The tuple must already be sorted
    # with respect to the block.  See Ruby's `Array#bsearch` for details,
    # behaviour is equivalent.
    #
    # @example
    #   t = Erlang::Tuple[1, 3, 5, 7, 9, 11, 13]
    #   # Block returns true/false for exact element match:
    #   t.bsearch { |e| e > 4 }      # => 5
    #   # Block returns number to match an element in 4 <= e <= 7:
    #   t.bsearch { |e| 1 - e / 4 }  # => 7
    #
    # @yield Once for at most `log n` elements, where `n` is the size of the
    #        tuple. The exact elements and ordering are undefined.
    # @yieldreturn [Boolean] `true` if this element matches the criteria, `false` otherwise.
    # @yieldreturn [Integer] See `Array#bsearch` for details.
    # @yieldparam [Object] element element to be evaluated
    # @return [Object] The matched element, or `nil` if none found.
    # @raise TypeError if the block returns a non-numeric, non-boolean, non-nil
    #                  value.
    def bsearch
      return enum_for(:bsearch) if not block_given?
      low, high, result = 0, @size, nil
      while low < high
        mid = (low + ((high - low) >> 1))
        val = get(mid)
        v   = yield val
        if v.is_a? Numeric
          if v == 0
            return val
          elsif v > 0
            high = mid
          else
            low = mid + 1
          end
        elsif v == true
          result = val
          high = mid
        elsif !v
          low = mid + 1
        else
          raise TypeError, "wrong argument type #{v.class} (must be numeric, true, false, or nil)"
        end
      end
      return result
    end

    # Return an empty `Tuple` instance, of the same class as this one. Useful if you
    # have multiple subclasses of `Tuple` and want to treat them polymorphically.
    #
    # @return [Tuple]
    def clear
      return self.class.empty
    end

    # Return a randomly chosen element from this `Tuple`. If the tuple is empty, return `nil`.
    #
    # @example
    #   Erlang::Tuple[1, 2, 3, 4, 5].sample  # => 2
    #
    # @return [Object]
    def sample
      return get(rand(@size))
    end

    # Return a new `Tuple` with only the elements at the given `indices`, in the
    # order specified by `indices`. If any of the `indices` do not exist, `nil`s will
    # appear in their places.
    #
    # @example
    #   t = Erlang::Tuple["A", "B", "C", "D", "E", "F"]
    #   t.values_at(2, 4, 5)   # => Erlang::Tuple["C", "E", "F"]
    #
    # @param indices [Array] The indices to retrieve and gather into a new `Tuple`
    # @return [Tuple]
    def values_at(*indices)
      return self.class.new(indices.map { |i| get(i) }.freeze)
    end

    # Find the index of an element, starting from the end of the tuple.
    # Returns `nil` if no element is found.
    #
    # @overload rindex(obj)
    #   Return the index of the last element which is `#==` to `obj`.
    #
    #   @example
    #     t = Erlang::Tuple[7, 8, 9, 7, 8, 9]
    #     t.rindex(8) # => 4
    #
    # @overload rindex
    #   Return the index of the last element for which the block returns true.
    #
    #   @yield [element] Once for each element, last to first, until the block
    #                    returns true.
    #   @example
    #     t = Erlang::Tuple[7, 8, 9, 7, 8, 9]
    #     t.rindex { |e| e.even? }  # => 4
    #
    # @return [Integer]
    def rindex(obj = (missing_arg = true))
      obj = Erlang.from(obj)
      i = @size - 1
      if missing_arg
        if block_given?
          reverse_each { |element| return i if yield element; i -= 1 }
          return nil
        else
          return enum_for(:rindex)
        end
      else
        reverse_each { |element| return i if element == obj; i -= 1 }
        return nil
      end
    end

    # Assumes all elements are nested, indexable collections, and searches through them,
    # comparing `obj` with the first element of each nested collection. Return the
    # first nested collection which matches, or `nil` if none is found.
    # Behaviour is undefined when elements do not meet assumptions (i.e. are
    # not indexable collections).
    #
    # @example
    #   t = Erlang::Tuple[Erlang::Tuple["A", 10], Erlang::Tuple["B", 20], Erlang::Tuple["C", 30]]
    #   t.assoc("B")  # => Erlang::Tuple["B", 20]
    #
    # @param obj [Object] The object to search for
    # @return [Object]
    def assoc(obj)
      obj = Erlang.from(obj)
      each do |array|
        next if !array.respond_to?(:[])
        return array if obj == array[0]
      end
      return nil
    end

    # Assumes all elements are nested, indexable collections, and searches through them,
    # comparing `obj` with the second element of each nested collection. Return
    # the first nested collection which matches, or `nil` if none is found.
    # Behaviour is undefined when elements do not meet assumptions (i.e. are
    # not indexable collections).
    #
    # @example
    #   t = Erlang::Tuple[Erlang::Tuple["A", 10], Erlang::Tuple["B", 20], Erlang::Tuple["C", 30]]
    #   t.rassoc(20)  # => Erlang::Tuple["B", 20]
    #
    # @param obj [Object] The object to search for
    # @return [Object]
    def rassoc(obj)
      obj = Erlang.from(obj)
      each do |array|
        next if !array.respond_to?(:[])
        return array if obj == array[1]
      end
      return nil
    end

    # Return an `Array` with the same elements, in the same order. The returned
    # `Array` may or may not be frozen.
    #
    # @return [Array]
    def to_a
      if @levels == 0
        # When initializing a Tuple with 32 or less elements, we always make
        # sure @root is frozen, so we can return it directly here
        return @root
      else
        return flatten_node(@root, @levels * BITS_PER_LEVEL, [])
      end
    end
    alias :to_ary :to_a

    # Return true if `other` has the same type and contents as this `Tuple`.
    #
    # @param other [Object] The collection to compare with
    # @return [Boolean]
    def eql?(other)
      return true if other.equal?(self)
      if instance_of?(other.class)
        return false if @size != other.size
        return @root.eql?(other.instance_variable_get(:@root))
      else
        return !!(Erlang.compare(other, self) == 0)
      end
    end
    alias :== :eql?

    # See `Object#hash`.
    # @return [Integer]
    def hash
      return reduce(Erlang::Tuple.hash) { |hash, item| (hash << 5) - hash + item.hash }
    end

    # @return [::Array]
    # @private
    def marshal_dump
      return to_a
    end

    # @private
    def marshal_load(array)
      initialize(array.freeze)
      __send__(:immutable!)
      return self
    end

    # Allows this `Tuple` to be printed using `Erlang.inspect()`.
    #
    # @return [String]
    def erlang_inspect(raw = false)
      result = '{'
      each_with_index { |obj, i| result << ',' if i > 0; result << Erlang.inspect(obj, raw: raw) }
      result << '}'
      return result
    end

  private

    def traverse_depth_first(node, level, &block)
      return node.each(&block) if level == 0
      return node.each { |child| traverse_depth_first(child, level - 1, &block) }
    end

    def reverse_traverse_depth_first(node, level, &block)
      return node.reverse_each(&block) if level == 0
      return node.reverse_each { |child| reverse_traverse_depth_first(child, level - 1, &block) }
    end

    def leaf_node_for(node, bitshift, index)
      while bitshift > 0
        node = node[(index >> bitshift) & INDEX_MASK]
        bitshift -= BITS_PER_LEVEL
      end
      return node
    end

    def update_root(index, item)
      root, levels = @root, @levels
      while index >= (1 << (BITS_PER_LEVEL * (levels + 1)))
        root = [root].freeze
        levels += 1
      end
      new_root = update_leaf_node(root, levels * BITS_PER_LEVEL, index, item)
      if new_root.equal?(root)
        return self
      else
        return self.class.alloc(new_root, @size > index ? @size : index + 1, levels)
      end
    end

    def update_leaf_node(node, bitshift, index, item)
      slot_index = (index >> bitshift) & INDEX_MASK
      if bitshift > 0
        old_child = node[slot_index] || []
        item = update_leaf_node(old_child, bitshift - BITS_PER_LEVEL, index, item)
      end
      existing_item = node[slot_index]
      if existing_item.equal?(item)
        return node
      else
        return node.dup.tap { |n| n[slot_index] = item }.freeze
      end
    end

    def flatten_range(node, bitshift, from, to)
      from_slot = (from >> bitshift) & INDEX_MASK
      to_slot   = (to   >> bitshift) & INDEX_MASK

      if bitshift == 0 # are we at the bottom?
        return node.slice(from_slot, to_slot-from_slot+1)
      elsif from_slot == to_slot
        return flatten_range(node[from_slot], bitshift - BITS_PER_LEVEL, from, to)
      else
        # the following bitmask can be used to pick out the part of the from/to indices
        #   which will be used to direct path BELOW this node
        mask   = ((1 << bitshift) - 1)
        result = []

        if from & mask == 0
          flatten_node(node[from_slot], bitshift - BITS_PER_LEVEL, result)
        else
          result.concat(flatten_range(node[from_slot], bitshift - BITS_PER_LEVEL, from, from | mask))
        end

        (from_slot+1).upto(to_slot-1) do |slot_index|
          flatten_node(node[slot_index], bitshift - BITS_PER_LEVEL, result)
        end

        if to & mask == mask
          flatten_node(node[to_slot], bitshift - BITS_PER_LEVEL, result)
        else
          result.concat(flatten_range(node[to_slot], bitshift - BITS_PER_LEVEL, to & ~mask, to))
        end

        return result
      end
    end

    def flatten_node(node, bitshift, result)
      if bitshift == 0
        result.concat(node)
      elsif bitshift == BITS_PER_LEVEL
        node.each { |a| result.concat(a) }
      else
        bitshift -= BITS_PER_LEVEL
        node.each { |a| flatten_node(a, bitshift, result) }
      end
      return result
    end

    def subsequence(from, length)
      return nil if from > @size || from < 0 || length < 0
      length = @size - from if @size < from + length
      return self.class.empty if length == 0
      return self.class.new(flatten_range(@root, @levels * BITS_PER_LEVEL, from, from + length - 1))
    end

    def flatten_suffix(node, bitshift, from, result)
      from_slot = (from >> bitshift) & INDEX_MASK

      if bitshift == 0
        if from_slot == 0
          return result.concat(node)
        else
          return result.concat(node.slice(from_slot, 32)) # entire suffix of node. excess length is ignored by #slice
        end
      else
        mask = ((1 << bitshift) - 1)
        if from & mask == 0
          from_slot.upto(node.size-1) do |i|
            flatten_node(node[i], bitshift - BITS_PER_LEVEL, result)
          end
        elsif child = node[from_slot]
          flatten_suffix(child, bitshift - BITS_PER_LEVEL, from, result)
          (from_slot+1).upto(node.size-1) do |i|
            flatten_node(node[i], bitshift - BITS_PER_LEVEL, result)
          end
        end
        return result
      end
    end

    def replace_suffix(from, suffix)
      # new suffix can go directly after existing elements
      raise IndexError if from > @size
      root, levels = @root, @levels

      if (from >> (BITS_PER_LEVEL * (@levels + 1))) != 0
        # index where new suffix goes doesn't fall within current tree
        # we will need to deepen tree
        root = [root].freeze
        levels += 1
      end

      new_size = from + suffix.size
      root = replace_node_suffix(root, levels * BITS_PER_LEVEL, from, suffix)

      if !suffix.empty?
        levels.times { suffix = suffix.each_slice(32).to_a }
        root.concat(suffix)
        while root.size > 32
          root = root.each_slice(32).to_a
          levels += 1
        end
      else
        while root.size == 1 && levels > 0
          root = root[0]
          levels -= 1
        end
      end

      return self.class.alloc(root.freeze, new_size, levels)
    end

    def replace_node_suffix(node, bitshift, from, suffix)
      from_slot = (from >> bitshift) & INDEX_MASK

      if bitshift == 0
        if from_slot == 0
          return suffix.shift(32)
        else
          return node.take(from_slot).concat(suffix.shift(32 - from_slot))
        end
      else
        mask = ((1 << bitshift) - 1)
        if from & mask == 0
          if from_slot == 0
            new_node = suffix.shift(32 * (1 << bitshift))
            while bitshift != 0
              new_node = new_node.each_slice(32).to_a
              bitshift -= BITS_PER_LEVEL
            end
            return new_node
          else
            result = node.take(from_slot)
            remainder = suffix.shift((32 - from_slot) * (1 << bitshift))
            while bitshift != 0
              remainder = remainder.each_slice(32).to_a
              bitshift -= BITS_PER_LEVEL
            end
            return result.concat(remainder)
          end
        elsif child = node[from_slot]
          result = node.take(from_slot)
          result.push(replace_node_suffix(child, bitshift - BITS_PER_LEVEL, from, suffix))
          remainder = suffix.shift((31 - from_slot) * (1 << bitshift))
          while bitshift != 0
            remainder = remainder.each_slice(32).to_a
            bitshift -= BITS_PER_LEVEL
          end
          return result.concat(remainder)
        else
          raise "Shouldn't happen"
        end
      end
    end
  end

  # The canonical empty `Tuple`. Returned by `Tuple[]` when
  # invoked with no arguments; also returned by `Tuple.empty`. Prefer using this
  # one rather than creating many empty tuples using `Tuple.new`.
  #
  # @private
  EmptyTuple = Erlang::Tuple.empty
end
