require 'spec_helper'

describe Erlang::List do
  describe '#inspect' do
    context 'improper list' do
      subject { Erlang::List[:a].tap { |list| list.tail = :b } }

      it { should be_improper }
      it 'formats as #<Erlang::List [:a | :b]>' do
        expect(subject.inspect).to eq("#<Erlang::List [:a | :b]>")
      end
    end

    context 'proper list' do
      subject { Erlang::List[:a, :b] }

      it { should_not be_improper }
      it 'formats as #<Erlang::List [:a, :b | []]>' do
        expect(subject.inspect).to eq("#<Erlang::List [:a, :b | []]>")
      end
    end
  end
end