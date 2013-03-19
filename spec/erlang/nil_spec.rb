require 'spec_helper'

describe Erlang::Nil do
  describe '#inspect' do
    subject { Erlang::Nil.new }

    it 'formats as #<Erlang::Nil []>' do
      expect(subject.inspect).to eq("#<Erlang::Nil []>")
    end

    it 'compares with other nil (and [])' do
      expect(subject).to eq(subject)
      expect(subject).to eq(Erlang::Nil.new)
      expect(subject).to eq([])
      expect(subject).to_not eq([:a])
    end
  end
end
