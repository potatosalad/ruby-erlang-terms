module Erlang
  class Compressed
    include Erlang::Term
    include Erlang::Immutable

    LEVEL_RANGE = (0..9).freeze
    LEVEL_DEFAULT = 6.freeze

    def self.[](data, level = LEVEL_DEFAULT)
      if level == false
        return data.__erlang_term__
      else
        return new(data, level)
      end
    end

    attr_reader :data, :level

    def initialize(data, level = LEVEL_DEFAULT)
      raise ArgumentError, 'level must be true, false, or an Integer between 0 and 9' if level != true and level != false and not LEVEL_RANGE.include?(level)
      level = LEVEL_DEFAULT if level == true
      @data = data.__erlang_term__
      @level = level
    end

    ## Erlang::Term

    def __erlang_print__
      return data.__erlang_print__
    end

    ## Ruby Object

    def ==(other)
      return data == other
    end

    def eql?(other)
      return data.eql?(other)
    end

    # @return [String] the nicely formatted version of the message
    def inspect
      if level == false
        return data.inspect
      else
        return "Erlang::Compressed[#{data.inspect}, #{level.inspect}]"
      end
    end
  end
end
