require 'spec_helper'

describe Erlang::Tuple do
  describe '#inspect' do
    subject { Erlang::Tuple[:a, 1, "one"] }

    it 'formats as #<Erlang::Tuple {:a, 1, "one"}>' do
      expect(subject.inspect).to eq('#<Erlang::Tuple {:a, 1, "one"}>')
    end

    it 'has {} in pretty_inspect' do
      expect(Erlang::Tuple[].pretty_inspect).to include("{}")
      expect(Erlang::Tuple[Erlang::Tuple[]].pretty_inspect).to include("{{}}")
    end

    it 'arity equals length' do
      expect(subject.arity).to eq(subject.length)
    end
  end
end
