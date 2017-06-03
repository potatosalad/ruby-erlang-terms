module Erlang
  # Helper module for Erlang sequential collections
  #
  # Classes including `Erlang::Enumerable` must implement:
  #
  # - `#each` (just like `::Enumerable`).
  # - `#select`, which takes a block, and returns an instance of the same class
  #     with only the items for which the block returns a true value
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
  module Enumerable
    include ::Enumerable

    # Return a new collection with all the elements for which the block returns false.
    def reject
      return enum_for(:reject) if not block_given?
      return select { |item| !yield(item) }
    end
    alias :delete_if :reject

    # Return a new collection with all `nil` elements removed.
    def compact
      return select { |item| !item.nil? }
    end

    # Search the collection for elements which are `#===` to `item`. Yield them to
    # the optional code block if provided, and return them as a new collection.
    def grep(pattern, &block)
      result = select { |item| pattern === item }
      result = result.map(&block) if block_given?
      return result
    end

    # Search the collection for elements which are not `#===` to `item`. Yield
    # them to the optional code block if provided, and return them as a new
    # collection.
    def grep_v(pattern, &block)
      result = select { |item| !(pattern === item) }
      result = result.map(&block) if block_given?
      return result
    end

    # Yield all integers from 0 up to, but not including, the number of items in
    # this collection. For collections which provide indexed access, these are all
    # the valid, non-negative indices into the collection.
    def each_index(&block)
      return enum_for(:each_index) unless block_given?
      0.upto(size-1, &block)
      return self
    end

    # Multiply all the items (presumably numeric) in this collection together.
    def product
      return reduce(1, &:*)
    end

    # Add up all the items (presumably numeric) in this collection.
    def sum
      return reduce(0, &:+)
    end

    # Return 2 collections, the first containing all the elements for which the block
    # evaluates to true, the second containing the rest.
    def partition
      return enum_for(:partition) if not block_given?
      a,b = super
      return Erlang::Tuple[self.class.new(a), self.class.new(b)]
    end

    # Groups the collection into sub-collections by the result of yielding them to
    # the block. Returns a {Map} where the keys are return values from the block,
    # and the values are sub-collections. All the sub-collections are built up from
    # `empty_group`, which should respond to `#add` by returning a new collection
    # with an added element.
    def group_by_with(empty_group, &block)
      block ||= lambda { |item| item }
      return reduce(EmptyMap) do |map, item|
        key = block.call(item)
        group = map.get(key) || empty_group
        map.put(key, group.add(item))
      end
    end
    protected :group_by_with

    # Groups the collection into sub-collections by the result of yielding them to
    # the block. Returns a {Map} where the keys are return values from the block,
    # and the values are sub-collections (of the same type as this one).
    def group_by(&block)
      return group_by_with(self.class.empty, &block)
    end

    # Convert all the elements into strings and join them together, separated by
    # `separator`. By default, the `separator` is `$,`, the global default string
    # separator, which is normally `nil`.
    def join(separator = $,)
      result = ""
      if separator
        each_with_index { |obj, i| result << separator if i > 0; result << obj.to_s }
      else
        each { |obj| result << obj.to_s }
      end
      return Erlang.from(result)
    end

    # Convert this collection to a programmer-readable `String` representation.
    def inspect
      result = "#{self.class}["
      each_with_index { |obj, i| result << ', ' if i > 0; result << obj.inspect }
      return result << "]"
    end

    # @private
    def pretty_print(pp)
      return pp.group(1, "#{self.class}[", "]") do
        pp.breakable ''
        pp.seplist(self) { |obj| obj.pretty_print(pp) }
      end
    end

    alias :to_ary :to_a
    alias :index :find_index

    ## Compatibility fixes

    if RUBY_ENGINE == 'rbx'
      # Rubinius implements Enumerable#sort_by using Enumerable#map
      # Because we do our own, custom implementations of #map, that doesn't work well
      # @private
      def sort_by(&block)
        result = Erlang.from(to_a)
        return result.frozen? ? result.sort_by(&block) : result.sort_by!(&block)
      end
    end
  end
end
