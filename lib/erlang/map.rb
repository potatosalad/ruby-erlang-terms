module Erlang
  # A `Erlang::Map` maps a set of unique keys to corresponding values, much
  # like a dictionary maps from words to definitions. Given a key, it can store
  # and retrieve an associated value in constant time. If an existing key is
  # stored again, the new value will replace the old. It behaves much like
  # Ruby's built-in Hash, which we will call RubyHash for clarity. Like
  # RubyHash, two keys that are `#eql?` to each other and have the same
  # `#hash` are considered identical in a `Erlang::Map`.
  #
  # A `Erlang::Map` can be created in a couple of ways:
  #
  #     Erlang::Map[first_name: 'John', last_name: 'Smith']
  #     Erlang::Map[:first_name, 'John', :last_name, 'Smith']
  #
  # Any `Enumerable` object with an even number of elements can be used to
  # initialize a `Erlang::Map`:
  #
  #     Erlang::Map[:first_name, 'John', :last_name, 'Smith']
  #
  # Any `Enumerable` object which yields two-element `[key, value]` arrays
  # can be used to initialize a `Erlang::Map`:
  #
  #     Erlang::Map.new([[:first_name, 'John'], [:last_name, 'Smith']])
  #
  # Key/value pairs can be added using {#put}. A new map is returned and the
  # existing one is left unchanged:
  #
  #     map = Erlang::Map[a: 100, b: 200]
  #     map.put(:c, 500) # => Erlang::Map[:a => 100, :b => 200, :c => 500]
  #     map              # => Erlang::Map[:a => 100, :b => 200]
  #
  # {#put} can also take a block, which is used to calculate the value to be
  # stored.
  #
  #     map.put(:a) { |current| current + 200 } # => Erlang::Map[:a => 300, :b => 200]
  #
  # Since it is immutable, all methods which you might expect to "modify" a
  # `Erlang::Map` actually return a new map and leave the existing one
  # unchanged. This means that the `map[key] = value` syntax from RubyHash
  # *cannot* be used with `Erlang::Map`.
  #
  # Nested data structures can easily be updated using {#update_in}:
  #
  #     map = Erlang::Map["a" => Erlang::Tuple[Erlang::Map["c" => 42]]]
  #     map.update_in("a", 0, "c") { |value| value + 5 }
  #     # => Erlang::Map["a" => Erlang::Tuple[Erlang::Map["c" => 47]]]
  #
  # While a `Erlang::Map` can iterate over its keys or values, it does not
  # guarantee any specific iteration order (unlike RubyHash). Methods like
  # {#flatten} do not guarantee the order of returned key/value pairs.
  #
  # Like RubyHash, a `Erlang::Map` can have a default block which is used
  # when looking up a key that does not exist. Unlike RubyHash, the default
  # block will only be passed the missing key, without the hash itself:
  #
  #     map = Erlang::Map.new { |missing_key| missing_key * 10 }
  #     map[5] # => 50
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
  class Map
    include Erlang::Term
    include Erlang::Immutable
    include Erlang::Enumerable
    include Erlang::Associable

    # Return the number of pairs in this `Map`
    # @return [Integer]
    attr_reader :arity
    alias :size :arity

    class << self
      # Create a new `Map` populated with the given key/value pairs.
      #
      # @example
      #   Erlang::Map["A" => 1, "B" => 2] # => Erlang::Map["A" => 1, "B" => 2]
      #   Erlang::Map["A", 1, "B", 2] # => Erlang::Map["A" => 1, "B" => 2]
      #
      # @param pairs [::Enumerable] initial content of hash. An empty hash is returned if not provided.
      # @return [Map]
      def [](*pairs)
        return empty if pairs.nil? or pairs.empty?
        if pairs.size == 1
          return pairs[0] if pairs[0].is_a?(Erlang::Map)
          return new(pairs[0]) if pairs[0].is_a?(::Hash)
        end
        raise ArgumentError, 'odd number of arguments for Erlang::Map' if pairs.size.odd?
        pairs = pairs.each_slice(2).to_a
        return new(pairs)
      end

      # Return an empty `Map`. If used on a subclass, returns an empty instance
      # of that class.
      #
      # @return [Map]
      def empty
        return @empty ||= self.new
      end

      # "Raw" allocation of a new `Map`. Used internally to create a new
      # instance quickly after obtaining a modified {Trie}.
      #
      # @return [Map]
      # @private
      def alloc(trie = EmptyTrie, block = nil)
        obj = allocate
        obj.instance_variable_set(:@trie, trie)
        obj.instance_variable_set(:@default, block)
        return obj
      end

      def compare(a, b)
        raise ArgumentError, "'a' must be of Erlang::Map type" if not a.kind_of?(Erlang::Map)
        raise ArgumentError, "'b' must be of Erlang::Map type" if not b.kind_of?(Erlang::Map)
        c = a.size <=> b.size
        return c if c != 0
        return 0 if a.eql?(b)
        return Erlang.compare(a.sort, b.sort)
      end
    end

    # @param pairs [::Enumerable] initial content of map. An empty map is returned if not provided.
    # @yield [key] Optional _default block_ to be stored and used to calculate the default value of a missing key. It will not be yielded during this method. It will not be preserved when marshalling.
    # @yieldparam key Key that was not present in the map.
    def initialize(pairs = nil, &block)
      if pairs
        obj = ::Array.new(pairs.size)
        i = 0
        pairs.each do |key, val|
          obj[i] = [Erlang.from(key), Erlang.from(val)]
          i += 1
        end
        pairs = obj
      end
      @trie = pairs ? Trie[pairs] : EmptyTrie
      @default = block
      if block_given?
        @default = ->(key) {
          return Erlang.from(block.call(key))
        }
      end
    end

    # Return the default block if there is one. Otherwise, return `nil`.
    #
    # @return [Proc]
    def default_proc
      return @default
    end

    # Return the number of key/value pairs in this `Map`.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3].size  # => 3
    #
    # @return [Integer]
    def size
      return @trie.size
    end
    alias :arity :size
    alias :length :size

    # Return `true` if this `Map` contains no key/value pairs.
    #
    # @return [Boolean]
    def empty?
      return @trie.empty?
    end

    # Return `true` if the given key object is present in this `Map`. More precisely,
    # return `true` if a key with the same `#hash` code, and which is also `#eql?`
    # to the given key object is present.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3].key?("B")  # => true
    #
    # @param key [Object] The key to check for
    # @return [Boolean]
    def key?(key)
      key = Erlang.from(key)
      return @trie.key?(key)
    end
    alias :has_key? :key?
    alias :include? :key?
    alias :member?  :key?

    # Return `true` if this `Map` has one or more keys which map to the provided value.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3].value?(2)  # => true
    #
    # @param value [Object] The value to check for
    # @return [Boolean]
    def value?(value)
      value = Erlang.from(value)
      each { |k,v| return true if value == v }
      return false
    end
    alias :has_value? :value?

    # Retrieve the value corresponding to the provided key object. If not found, and
    # this `Map` has a default block, the default block is called to provide the
    # value. Otherwise, return `nil`.
    #
    # @example
    #   m = Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #   m["B"]             # => 2
    #   m.get("B")         # => 2
    #   m.get("Elephant")  # => nil
    #
    #   # Erlang Map with a default proc:
    #   m = Erlang::Map.new("A" => 1, "B" => 2, "C" => 3) { |key| key.size }
    #   m.get("B")         # => 2
    #   m.get("Elephant")  # => 8
    #
    # @param key [Object] The key to look up
    # @return [Object]
    def get(key)
      key = Erlang.from(key)
      entry = @trie.get(key)
      if entry
        return entry[1]
      elsif @default
        return @default.call(key)
      end
    end
    alias :[] :get

    # Retrieve the value corresponding to the given key object, or use the provided
    # default value or block, or otherwise raise a `KeyError`.
    #
    # @overload fetch(key)
    #   Retrieve the value corresponding to the given key, or raise a `KeyError`
    #   if it is not found.
    #   @param key [Object] The key to look up
    # @overload fetch(key) { |key| ... }
    #   Retrieve the value corresponding to the given key, or call the optional
    #   code block (with the missing key) and get its return value.
    #   @yield [key] The key which was not found
    #   @yieldreturn [Object] Object to return since the key was not found
    #   @param key [Object] The key to look up
    # @overload fetch(key, default)
    #   Retrieve the value corresponding to the given key, or else return
    #   the provided `default` value.
    #   @param key [Object] The key to look up
    #   @param default [Object] Object to return if the key is not found
    #
    # @example
    #   m = Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #   m.fetch("B")         # => 2
    #   m.fetch("Elephant")  # => KeyError: key not found: "Elephant"
    #
    #   # with a default value:
    #   m.fetch("B", 99)         # => 2
    #   m.fetch("Elephant", 99)  # => 99
    #
    #   # with a block:
    #   m.fetch("B") { |key| key.size }         # => 2
    #   m.fetch("Elephant") { |key| key.size }  # => 8
    #
    # @return [Object]
    def fetch(key, default = Undefined)
      key = Erlang.from(key)
      entry = @trie.get(key)
      if entry
        return entry[1]
      elsif block_given?
        return yield(key)
      elsif not Undefined.equal?(default)
        return Erlang.from(default)
      else
        raise KeyError, "key not found: #{key.inspect}"
      end
    end

    # Return a new `Map` with the existing key/value associations, plus an association
    # between the provided key and value. If an equivalent key is already present, its
    # associated value will be replaced with the provided one.
    #
    # If the `value` argument is missing, but an optional code block is provided,
    # it will be passed the existing value (or `nil` if there is none) and what it
    # returns will replace the existing value. This is useful for "transforming"
    # the value associated with a certain key.
    #
    # Avoid mutating objects which are used as keys. `String`s are an exception:
    # unfrozen `String`s which are used as keys are internally duplicated and
    # frozen. This matches RubyHash's behaviour.
    #
    # @example
    #   m = Erlang::Map["A" => 1, "B" => 2]
    #   m.put("C", 3)
    #   # => Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #   m.put("B") { |value| value * 10 }
    #   # => Erlang::Map["A" => 1, "B" => 20]
    #
    # @param key [Object] The key to store
    # @param value [Object] The value to associate it with
    # @yield [value] The previously stored value, or `nil` if none.
    # @yieldreturn [Object] The new value to store
    # @return [Map]
    def put(key, value = yield(get(key)))
      new_trie = @trie.put(Erlang.from(key), Erlang.from(value))
      if new_trie.equal?(@trie)
        return self
      else
        return self.class.alloc(new_trie, @default)
      end
    end

    # @!method update_in(*key_path, &block)
    # Return a new `Map` with a deeply nested value modified to the result of
    # the given code block.  When traversing the nested `Map`es and `Tuple`s,
    # non-existing keys are created with empty `Map` values.
    #
    # The code block receives the existing value of the deeply nested key (or
    # `nil` if it doesn't exist). This is useful for "transforming" the value
    # associated with a certain key.
    #
    # Note that the original `Map` and sub-`Map`es and sub-`Tuple`s are left
    # unmodified; new data structure copies are created along the path wherever
    # needed.
    #
    # @example
    #   map = Erlang::Map["a" => Erlang::Map["b" => Erlang::Map["c" => 42]]]
    #   map.update_in("a", "b", "c") { |value| value + 5 }
    #   # => Erlang::Map["a" => Erlang::Map["b" => Erlang::Map["c" => 47]]]
    #
    # @param key_path [::Array<Object>] List of keys which form the path to the key to be modified
    # @yield [value] The previously stored value
    # @yieldreturn [Object] The new value to store
    # @return [Map]
    # @see Associable#update_in

    # An alias for {#put} to match RubyHash's API. Does not support {#put}'s
    # block form.
    #
    # @see #put
    # @param key [Object] The key to store
    # @param value [Object] The value to associate it with
    # @return [Map]
    def store(key, value)
      return put(key, value)
    end

    # Return a new `Map` with `key` removed. If `key` is not present, return
    # `self`.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3].delete("B")
    #   # => Erlang::Map["A" => 1, "C" => 3]
    #
    # @param key [Object] The key to remove
    # @return [Map]
    def delete(key)
      return derive_new_map(@trie.delete(key))
    end

    # Call the block once for each key/value pair in this `Map`, passing the key/value
    # pair as parameters. No specific iteration order is guaranteed, though the order will
    # be stable for any particular `Map`.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3].each { |k, v| puts "k=#{k} v=#{v}" }
    #
    #   k=A v=1
    #   k=C v=3
    #   k=B v=2
    #   # => Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #
    # @yield [key, value] Once for each key/value pair.
    # @return [self]
    def each(&block)
      return to_enum if not block_given?
      @trie.each(&block)
      return self
    end
    alias :each_pair :each

    # Call the block once for each key/value pair in this `Map`, passing the key/value
    # pair as parameters. Iteration order will be the opposite of {#each}.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3].reverse_each { |k, v| puts "k=#{k} v=#{v}" }
    #
    #   k=B v=2
    #   k=C v=3
    #   k=A v=1
    #   # => Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #
    # @yield [key, value] Once for each key/value pair.
    # @return [self]
    def reverse_each(&block)
      return enum_for(:reverse_each) if not block_given?
      @trie.reverse_each(&block)
      return self
    end

    # Call the block once for each key/value pair in this `Map`, passing the key as a
    # parameter. Ordering guarantees are the same as {#each}.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3].each_key { |k| puts "k=#{k}" }
    #
    #   k=A
    #   k=C
    #   k=B
    #   # => Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #
    # @yield [key] Once for each key/value pair.
    # @return [self]
    def each_key
      return enum_for(:each_key) if not block_given?
      @trie.each { |k,v| yield k }
      return self
    end

    # Call the block once for each key/value pair in this `Map`, passing the value as a
    # parameter. Ordering guarantees are the same as {#each}.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3].each_value { |v| puts "v=#{v}" }
    #
    #   v=1
    #   v=3
    #   v=2
    #   # => Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #
    # @yield [value] Once for each key/value pair.
    # @return [self]
    def each_value
      return enum_for(:each_value) if not block_given?
      @trie.each { |k,v| yield v }
      return self
    end

    # Call the block once for each key/value pair in this `Map`, passing the key/value
    # pair as parameters. The block should return a `[key, value]` array each time.
    # All the returned `[key, value]` arrays will be gathered into a new `Map`.
    #
    # @example
    #   m = Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #   m.map { |k, v| ["new-#{k}", v * v] }
    #   # => Erlang::Map["new-C" => 9, "new-B" => 4, "new-A" => 1]
    #
    # @yield [key, value] Once for each key/value pair.
    # @return [Map]
    def map
      return enum_for(:map) unless block_given?
      return self if empty?
      return self.class.new(super, &@default)
    end
    alias :collect :map

    # Return a new `Map` with all the key/value pairs for which the block returns true.
    #
    # @example
    #   m = Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #   m.select { |k, v| v >= 2 }
    #   # => Erlang::Map["B" => 2, "C" => 3]
    #
    # @yield [key, value] Once for each key/value pair.
    # @yieldreturn Truthy if this pair should be present in the new `Map`.
    # @return [Map]
    def select(&block)
      return enum_for(:select) unless block_given?
      return derive_new_map(@trie.select(&block))
    end
    alias :find_all :select
    alias :keep_if  :select

    # Yield `[key, value]` pairs until one is found for which the block returns true.
    # Return that `[key, value]` pair. If the block never returns true, return `nil`.
    #
    # @example
    #   m = Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #   m.find { |k, v| v.even? }
    #   # => ["B", 2]
    #
    # @return [Array]
    # @yield [key, value] At most once for each key/value pair, until the block returns `true`.
    # @yieldreturn Truthy to halt iteration and return the yielded key/value pair.
    def find
      return enum_for(:find) unless block_given?
      each { |entry| return entry if yield entry }
      return nil
    end
    alias :detect :find

    # Return a new `Map` containing all the key/value pairs from this `Map` and
    # `other`. If no block is provided, the value for entries with colliding keys
    # will be that from `other`. Otherwise, the value for each duplicate key is
    # determined by calling the block.
    #
    # `other` can be a `Erlang::Map`, a built-in Ruby `Map`, or any `Enumerable`
    # object which yields `[key, value]` pairs.
    #
    # @example
    #   m1 = Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #   m2 = Erlang::Map["C" => 70, "D" => 80]
    #   m1.merge(m2)
    #   # => Erlang::Map["C" => 70, "A" => 1, "D" => 80, "B" => 2]
    #   m1.merge(m2) { |key, v1, v2| v1 + v2 }
    #   # => Erlang::Map["C" => 73, "A" => 1, "D" => 80, "B" => 2]
    #
    # @param other [::Enumerable] The collection to merge with
    # @yieldparam key [Object] The key which was present in both collections
    # @yieldparam my_value [Object] The associated value from this `Map`
    # @yieldparam other_value [Object] The associated value from the other collection
    # @yieldreturn [Object] The value to associate this key with in the new `Map`
    # @return [Map]
    def merge(other)
      other = Erlang.from(other)
      trie = if block_given?
        other.reduce(@trie) do |acc, (key, value)|
          if entry = acc.get(key)
            acc.put(key, yield(key, entry[1], value))
          else
            acc.put(key, value)
          end
        end
      else
        @trie.bulk_put(other)
      end

      return derive_new_map(trie)
    end

    # Return a sorted {List} which contains all the `[key, value]` pairs in
    # this `Map` as two-element `Tuple`s.
    #
    # @overload sort
    #   Uses `#<=>` to determine sorted order.
    # @overload sort { |(k1, v1), (k2, v2)| ... }
    #   Uses the block as a comparator to determine sorted order.
    #
    #   @example
    #     m = Erlang::Map["Dog" => 1, "Elephant" => 2, "Lion" => 3]
    #     m.sort { |(k1, v1), (k2, v2)| k1.size  <=> k2.size }
    #     # => Erlang::List[Erlang::Tuple["Dog", 1], Erlang::Tuple["Lion", 3], Erlang::Tuple["Elephant", 2]]
    #   @yield [(k1, v1), (k2, v2)] Any number of times with different pairs of key/value associations.
    #   @yieldreturn [Integer] Negative if the first pair should be sorted
    #                          lower, positive if the latter pair, or 0 if equal.
    #
    # @see ::Enumerable#sort
    #
    # @return [List]
    def sort(&comparator)
      comparator = Erlang.method(:compare) unless block_given?
      array = super(&comparator)
      array.map! { |k, v| next Erlang::Tuple[k, v] }
      return List.from_enum(array)
    end

    # Return a {List} which contains all the `[key, value]` pairs in this `Hash`
    # as two-element `Tuple`s. The order which the pairs will appear in is determined by
    # passing each pair to the code block to obtain a sort key object, and comparing
    # the sort keys using `#<=>`.
    #
    # @see ::Enumerable#sort_by
    #
    # @example
    #   m = Erlang::Map["Dog" => 1, "Elephant" => 2, "Lion" => 3]
    #   m.sort_by { |key, value| key.size }
    #   # => Erlang::List[Erlang::Tuple["Dog", 1], Erlang::Tuple["Lion", 3], Erlang::Tuple["Elephant", 2]]
    #
    # @yield [key, value] Once for each key/value pair.
    # @yieldreturn a sort key object for the yielded pair.
    # @return [List]
    def sort_by(&transformer)
      return sort unless block_given?
      block = ->(x) { Erlang.from(transformer.call(x)) }
      array = super(&block)
      array.map! { |k, v| next Erlang::Tuple[k, v] }
      return List.from_enum(array)
    end

    # Return a new `Map` with the associations for all of the given `keys` removed.
    #
    # @example
    #   m = Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #   m.except("A", "C")  # => Erlang::Map["B" => 2]
    #
    # @param keys [Array] The keys to remove
    # @return [Map]
    def except(*keys)
      return keys.reduce(self) { |map, key| map.delete(key) }
    end

    # Return a new `Map` with only the associations for the `wanted` keys retained.
    #
    # @example
    #   m = Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #   m.slice("B", "C")  # => Erlang::Map["B" => 2, "C" => 3]
    #
    # @param wanted [::Enumerable] The keys to retain
    # @return [Map]
    def slice(*wanted)
      trie = Trie.new(0)
      wanted.each { |key|
        key = Erlang.from(key)
        trie.put!(key, get(key)) if key?(key)
      }
      return self.class.alloc(trie, @default)
    end

    # Return a {List} of the values which correspond to the `wanted` keys.
    # If any of the `wanted` keys are not present in this `Map`, `nil` will be
    # placed instead, or the result of the default proc (if one is defined),
    # similar to the behavior of {#get}.
    #
    # @example
    #   m = Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #   m.values_at("B", "A", "D")  # => Erlang::List[2, 1, nil]
    #
    # @param wanted [Array] The keys to retrieve
    # @return [List]
    def values_at(*wanted)
      array = wanted.map { |key|
        key = Erlang.from(key)
        get(key)
      }
      return List.from_enum(array.freeze)
    end

    # Return a {List} of the values which correspond to the `wanted` keys.
    # If any of the `wanted` keys are not present in this `Map`, raise `KeyError`
    # exception.
    #
    # @example
    #   m = Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #   m.fetch_values("C", "A")  # => Erlang::List[3, 1]
    #   m.fetch_values("C", "Z")  # => KeyError: key not found: "Z"
    #
    # @param wanted [Array] The keys to retrieve
    # @return [Tuple]
    def fetch_values(*wanted)
      array = wanted.map { |key|
        key = Erlang.from(key)
        fetch(key)
      }
      return List.from_enum(array.freeze)
    end

    # Return a new {List} containing the keys from this `Map`.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3, "D" => 2].keys
    #   # => Erlang::List["D", "C", "B", "A"]
    #
    # @return [Set]
    def keys
      return Erlang::List.from_enum(each_key.to_a.freeze)
    end

    # Return a new {List} populated with the values from this `Map`.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3, "D" => 2].values
    #   # => Erlang::List[2, 3, 2, 1]
    #
    # @return [List]
    def values
      return Erlang::List.from_enum(each_value.to_a.freeze)
    end

    # Return a new `Map` created by using keys as values and values as keys.
    # If there are multiple values which are equivalent (as determined by `#hash` and
    # `#eql?`), only one out of each group of equivalent values will be
    # retained. Which one specifically is undefined.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3, "D" => 2].invert
    #   # => Erlang::Map[1 => "A", 3 => "C", 2 => "B"]
    #
    # @return [Map]
    def invert
      pairs = []
      each { |k,v| pairs << [v, k] }
      return self.class.new(pairs, &@default)
    end

    # Return a new {List} which is a one-dimensional flattening of this `Map`.
    # If `level` is 1, all the `[key, value]` pairs in the hash will be concatenated
    # into one {List}. If `level` is greater than 1, keys or values which are
    # themselves `Array`s or {List}s will be recursively flattened into the output
    # {List}. The depth to which that flattening will be recursively applied is
    # determined by `level`.
    #
    # As a special case, if `level` is 0, each `[key, value]` pair will be a
    # separate element in the returned {List}.
    #
    # @example
    #   m = Erlang::Map["A" => 1, "B" => [2, 3, 4]]
    #   m.flatten
    #   # => Erlang::List["A", 1, "B", [2, 3, 4]]
    #   h.flatten(2)
    #   # => Erlang::List["A", 1, "B", 2, 3, 4]
    #
    # @param level [Integer] The number of times to recursively flatten the `[key, value]` pairs in this `Map`.
    # @return [List]
    def flatten(level = 1)
      return List.from_enum(self) if level == 0
      array = []
      each { |k,v| array << k; array << v }
      array.flatten!(level-1) if level > 1
      return List.from_enum(array.freeze)
    end

    # Searches through the `Map`, comparing `obj` with each key (using `#==`).
    # When a matching key is found, return the `[key, value]` pair as a `Tuple`.
    # Return `nil` if no match is found.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3].assoc("B")  # => Erlang::Tuple["B", 2]
    #
    # @param obj [Object] The key to search for (using #==)
    # @return [Tuple]
    def assoc(obj)
      obj = Erlang.from(obj)
      each { |entry| return Erlang::Tuple[*entry] if obj == entry[0] }
      return nil
    end

    # Searches through the `Map`, comparing `obj` with each value (using `#==`).
    # When a matching value is found, return the `[key, value]` pair as a `Tuple`.
    # Return `nil` if no match is found.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3].rassoc(2)  # => Erlang::Tuple["B", 2]
    #
    # @param obj [Object] The value to search for (using #==)
    # @return [Tuple]
    def rassoc(obj)
      obj = Erlang.from(obj)
      each { |entry| return Erlang::Tuple[*entry] if obj == entry[1] }
      return nil
    end

    # Searches through the `Map`, comparing `value` with each value (using `#==`).
    # When a matching value is found, return its associated key object.
    # Return `nil` if no match is found.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3].key(2)  # => "B"
    #
    # @param value [Object] The value to search for (using #==)
    # @return [Object]
    def key(value)
      value = Erlang.from(value)
      each { |entry| return entry[0] if value == entry[1] }
      return nil
    end

    # Return a randomly chosen `[key, value]` pair from this `Map`. If the hash is empty,
    # return `nil`.
    #
    # @example
    #   Erlang::Map["A" => 1, "B" => 2, "C" => 3].sample
    #   # => Erlang::Tuple["C", 3]
    #
    # @return [Tuple]
    def sample
      return Erlang::Tuple[*@trie.at(rand(size))]
    end

    # Return an empty `Map` instance, of the same class as this one. Useful if you
    # have multiple subclasses of `Map` and want to treat them polymorphically.
    # Maintains the default block, if there is one.
    #
    # @return [Map]
    def clear
      if @default
        return self.class.alloc(EmptyTrie, @default)
      else
        return self.class.empty
      end
    end

    # Return true if `other` has the same type and contents as this `Map`.
    #
    # @param other [Object] The collection to compare with
    # @return [Boolean]
    def eql?(other)
      return true if other.equal?(self)
      return @trie.eql?(other.instance_variable_get(:@trie)) if instance_of?(other.class)
      return !!(Erlang.compare(other, self) == 0)
    end
    alias :== :eql?

    # See `Object#hash`.
    # @return [Integer]
    def hash
      return keys.sort.reduce(Erlang::Map.hash) do |acc, key|
        (acc << 32) - acc + key.hash + get(key).hash
      end
    end

    # Return the contents of this `Map` as a programmer-readable `String`. If all the
    # keys and values are serializable as Ruby literal strings, the returned string can
    # be passed to `eval` to reconstitute an equivalent `Map`. The default
    # block (if there is one) will be lost when doing this, however.
    #
    # @return [String]
    def inspect
      # result = "#{self.class}["
      result = "{"
      i = 0
      each do |key, val|
        result << ', ' if i > 0
        result << key.inspect << ' => ' << val.inspect
        i += 1
      end
      return result << "}"
    end

    # Allows this `Map` to be printed using `Erlang.inspect()`.
    #
    # @return [String]
    def erlang_inspect(raw = false)
      result = '#{'
      each_with_index do |(key, val), i|
        result << ',' if i > 0
        result << Erlang.inspect(key, raw: raw)
        result << ' => '
        result << Erlang.inspect(val, raw: raw)
      end
      return result << '}'
    end

    # Allows this `Map` to be printed at the `pry` console, or using `pp` (from the
    # Ruby standard library), in a way which takes the amount of horizontal space on
    # the screen into account, and which indents nested structures to make them easier
    # to read.
    #
    # @private
    def pretty_print(pp)
      # return pp.group(1, "#{self.class}[", "]") do
      return pp.group(1, "{", "}") do
        pp.breakable ''
        pp.seplist(self, nil) do |key, val|
          pp.group do
            key.pretty_print(pp)
            pp.text ' => '
            pp.group(1) do
              pp.breakable ''
              val.pretty_print(pp)
            end
          end
        end
      end
    end

    # Convert this `Erlang::Map` to an instance of Ruby's built-in `Hash`.
    #
    # @return [::Hash]
    def to_hash
      output = {}
      each do |key, value|
        output[key] = value
      end
      return output
    end
    alias :to_h :to_hash

    # Return a Proc which accepts a key as an argument and returns the value.
    # The Proc behaves like {#get} (when the key is missing, it returns nil or
    # result of the default proc).
    #
    # @example
    #   m = Erlang::Map["A" => 1, "B" => 2, "C" => 3]
    #   m.to_proc.call("B")
    #   # => 2
    #   ["A", "C", "X"].map(&h)   # The & is short for .to_proc in Ruby
    #   # => [1, 3, nil]
    #
    # @return [Proc]
    def to_proc
      return lambda { |key| get(key) }
    end

    # @return [::Hash]
    # @private
    def marshal_dump
      return to_hash
    end

    # @private
    def marshal_load(dictionary)
      @trie = Trie[dictionary]
      __send__(:immutable!)
      return self
    end

  private

    # Return a new `Map` which is derived from this one, using a modified {Trie}.
    # The new `Map` will retain the existing default block, if there is one.
    #
    def derive_new_map(trie)
      if trie.equal?(@trie)
        return self
      elsif trie.empty?
        if @default
          return self.class.alloc(EmptyTrie, @default)
        else
          return self.class.empty
        end
      else
        return self.class.alloc(trie, @default)
      end
    end

  end

  # The canonical empty `Map`. Returned by `Map[]` when
  # invoked with no arguments; also returned by `Map.empty`. Prefer using this
  # one rather than creating many empty hashes using `Map.new`.
  #
  # @private
  EmptyMap = Erlang::Map.empty
end
