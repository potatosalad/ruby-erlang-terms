# Erlang::Terms [![Build Status](https://travis-ci.org/potatosalad/ruby-erlang-terms.png)](https://travis-ci.org/potatosalad/ruby-erlang-terms) [![Coverage Status](https://coveralls.io/repos/potatosalad/ruby-erlang-terms/badge.png?branch=develop)](https://coveralls.io/r/potatosalad/ruby-erlang-terms?branch=develop)

Includes simple immutable classes that represent Erlang's atom, binary, bitstring, compressed, export, function, list, map, nil, pid, port, reference, string, and tuple.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'erlang-terms'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install erlang-terms
```

## Usage

The following classes show the [Erlang](http://www.erlang.org/) representation followed by the corresponding [Ruby](http://www.ruby-lang.org/) representation.

See [erlang-etf](https://github.com/potatosalad/ruby-erlang-etf) for more information.

### Erlang::Atom

```erlang
Atom     = 'test',
AtomUTF8 = 'Ω'.
```

```ruby
atom = Erlang::Atom[:test]
# => :test
atom_utf8 = Erlang::Atom[:Ω, utf8: true]
# => Erlang::Atom["Ω", utf8: true]
```

### Erlang::Binary

```erlang
Binary0 = <<>>,
Binary1 = <<"test">>,
Binary2 = <<0,1,2>>.
```

```ruby
binary0 = Erlang::Binary[]
# => ""
binary1 = Erlang::Binary["test"]
# => "test"
binary2 = Erlang::Binary[0,1,2]
# => "\x00\x01\x02"
```

### Erlang::Bitstring

```erlang
Bitstring0 = <<1:7>>,
Bitstring1 = <<"test",2:3>>.
```

```ruby
bitstring0 = Erlang::Bitstring[1, bits: 7]
# => Erlang::Bitstring[1, bits: 7]
bitstring1 = Erlang::Bitstring["test", 2, bits: 3]
# => Erlang::Bitstring[116, 101, 115, 116, 2, bits: 3]
```

### Erlang::Export

```erlang
Module   = erlang,
Function = now,
Arity    = 0,
Export   = fun Module:Function/Arity.
```

```ruby
export = Erlang::Export[:erlang, :now, 0]
# => Erlang::Export[:erlang, :now, 0]
```

### Erlang::Float

```erlang
Float = 1.0e12.
```

```ruby
float = Erlang::Float[1.0e12]
# => 1.00000000000000000000e+12
```

### Erlang::List

##### Improper List

```erlang
List = [a | b].
```

```ruby
list = Erlang::List[:a] + :b
# => Erlang::List[:a] + :b
list.improper?
# => true
```

##### Proper List

```erlang
List = [a, b].
```

```ruby
list = Erlang::List[:a, :b]
# => [:a, :b]
list.improper?
# => false
```

### Erlang::Map

```erlang
Map = #{atom => 1}.
```

```ruby
map = Erlang::Map[:atom, 1]
# => {:atom => 1}
```

### Erlang::Nil

```erlang
Nil = [].
```

```ruby
erlang_nil = Erlang::Nil
# => []
```

### Erlang::Pid

```erlang
Pid = self().

%% or

Id     = 100,
Serial = 5,
Pid    = pid(0, Id, Serial).

%% or

Pid = list_to_pid("<0.100.5>").
```

```ruby
pid = Erlang::Pid[:"node@host", 100, 5, 0]
# => Erlang::Pid[:"node@host", 100, 5, 0]
```

### Erlang::Port

```erlang
Port = hd(erlang:ports()).
```

```ruby
port = Erlang::Port[:"nonode@nohost", 0, 0]
# => Erlang::Port[:"nonode@nohost", 0, 0]
```

### Erlang::Reference

```erlang
Reference = erlang:make_ref().
```

```ruby
reference = Erlang::Reference[:"nonode@nohost", 0, [168, 2, 0]]
# => Erlang::Reference[:"nonode@nohost", 0, [168, 2, 0]]
```

### Erlang::String

```erlang
String = "test".
```

```ruby
string = Erlang::String["test"]
# => Erlang::String["test"]
```

### Erlang::Tuple

```erlang
Tuple = {atom, 1}.
```

```ruby
tuple = Erlang::Tuple[:atom, 1]
# => Erlang::Tuple[:atom, 1]
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
