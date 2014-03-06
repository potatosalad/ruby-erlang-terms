# Erlang::Terms [![Build Status](https://travis-ci.org/potatosalad/erlang-terms.png)](https://travis-ci.org/potatosalad/erlang-terms) [![Coverage Status](https://coveralls.io/repos/potatosalad/erlang-terms/badge.png)](https://coveralls.io/r/potatosalad/erlang-terms)

Includes simple classes that represent Erlang's export, list, pid, string, tuple, and map.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'erlang-terms', require: 'erlang/terms'
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

See [erlang-etf](https://github.com/potatosalad/erlang-etf) for more information.

### Erlang::Export

```erlang
Module   = erlang,
Function = now,
Arity    = 0,
Export   = fun Module:Function/Arity.
```

```ruby
export = Erlang::Export.new(:erlang, :now, 0)
# => #<Erlang::Export fun erlang:now/0>
```

### Erlang::List

##### Improper List

```erlang
List = [a | b].
```

```ruby
list = Erlang::List[:a].tail(:b)
# => #<Erlang::List [:a | :b]">
list.improper?
# => true
```

##### Proper List

```erlang
List = [a, b].
```

```ruby
list = Erlang::List[:a, :b]
# => #<Erlang::List [:a, :b | []]">
list.improper?
# => false
```

### Erlang::Map

```erlang
Map = #{atom => 1}.
```

```ruby
map = Erlang::Map[:atom, 1]
# => #<Erlang::Map #{:atom => 1}>
```

### Erlang::Nil

```erlang
Nil = [].
```

```ruby
erlang_nil = Erlang::Nil.new
# => #<Erlang::Nil []>
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
pid = Erlang::Pid.new('node@host', 100, 5, 0)
# => #<Erlang::Pid <0.100.5> @node="node@host" @creation=0>
```

### Erlang::String

```erlang
String = "test".
```

```ruby
string = Erlang::String.new("test")
# => #<Erlang::String "test">
```

### Erlang::Tuple

```erlang
Tuple = {atom, 1}.
```

```ruby
tuple = Erlang::Tuple[:atom, 1]
# => #<Erlang::Tuple {:atom, 1}>
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
