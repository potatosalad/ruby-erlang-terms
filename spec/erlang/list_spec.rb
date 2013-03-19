require 'spec_helper'

describe Erlang::List do
  describe '#inspect' do
    context 'improper list' do
      subject { Erlang::List[:a].tail(:b) }

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

  it 'has | [] in pretty_inspect' do
    expect(Erlang::List[:a].pretty_inspect).to include("| []")
  end

  context '#==' do
    subject { Erlang::List[:a, :b] }

    it 'compares with other lists' do
      expect(subject).to eq(subject)
      expect(subject).to eq(Erlang::List[:a, :b])
      expect(subject).to_not eq(Erlang::List[:a, :b].tail(:c))
      expect(subject).to eq([:a, :b])
      expect(Erlang::List[:a].tail(:c)).to_not eq([:a])
    end
  end
end