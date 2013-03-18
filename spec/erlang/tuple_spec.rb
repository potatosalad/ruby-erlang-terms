require 'spec_helper'

describe Erlang::Tuple do
  describe '#inspect' do
    subject { Erlang::Tuple[:a, 1, "one"] }

    it 'formats as #<Erlang::Tuple {:a, 1, "one"}>' do
      expect(subject.inspect).to eq('#<Erlang::Tuple {:a, 1, "one"}>')
    end
  end
end
