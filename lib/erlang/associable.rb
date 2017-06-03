module Erlang
  # Including `Associable` in your container class gives it an `update_in`
  # method.
  #
  # To mix in `Associable`, your class must implement two methods:
  #
  # * `fetch(index, default = (missing_default = true))`
  # * `put(index, item = yield(get(index)))`
  # * `get(key)`
  #
  # See {Tuple#fetch}, {Tuple#put}, {Map#fetch}, and {Map#put} for examples.
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
  module Associable
    # Return a new container with a deeply nested value modified to the result
    # of the given code block.  When traversing the nested containers
    # non-existing keys are created with empty `Hash` values.
    #
    # The code block receives the existing value of the deeply nested key/index
    # (or `nil` if it doesn't exist). This is useful for "transforming" the
    # value associated with a certain key/index.
    #
    # Naturally, the original container and sub-containers are left unmodified;
    # new data structure copies are created along the path as needed.
    #
    # @example
    #   t = Erlang::Tuple[123, 456, 789, Erlang::Map["a" => Erlang::Tuple[5, 6, 7]]]
    #   t.update_in(3, "a", 1) { |value| value + 9 }
    #   # => Erlang::Tuple[123, 456, 789, Erlang::Map["a'" => Erlang::Tuple[5, 15, 7]]]
    #   map = Erlang::Map["a" => Erlang::Map["b" => Erlang::Map["c" => 42]]]
    #   map.update_in("a", "b", "c") { |value| value + 5 }
    #   # => Erlang::Map["a" => Erlang::Map["b" => Erlang::Map["c" => 47]]]
    #
    # @param key_path [Object(s)] List of keys/indexes which form the path to the key to be modified
    # @yield [value] The previously stored value
    # @yieldreturn [Object] The new value to store
    # @return [Associable]
    def update_in(*key_path, &block)
      if key_path.empty?
        raise ArgumentError, "must have at least one key in path"
      end
      key = key_path[0]
      if key_path.size == 1
        new_value = block.call(fetch(key, nil))
      else
        value = fetch(key, EmptyMap)
        new_value = value.update_in(*key_path[1..-1], &block)
      end
      return put(key, new_value)
    end

    # Return the value of successively indexing into a collection.
    # If any of the keys is not present in the collection, return `nil`.
    # keys that the Erlang type doesn't understand, raises an argument error
    #
    # @example
    #   m = Erlang::Map[:a => 9, :b => Erlang::Tuple['a', 'b'], :e => nil]
    #   m.dig(:b, 0)    # => "a"
    #   m.dig(:b, 5)    # => nil
    #   m.dig(:b, 0, 0) # => nil
    #   m.dig(:b, :a)   # ArgumentError
    # @param key to fetch from the collection
    # @return [Object]
    def dig(key, *rest)
      value = get(key)
      if rest.empty? || value.nil?
        return value
      elsif value.respond_to?(:dig)
        return value.dig(*rest)
      end
    end
  end
end
