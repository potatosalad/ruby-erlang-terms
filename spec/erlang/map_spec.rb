require 'spec_helper'

describe Erlang::Map do
  describe '#inspect' do
    subject { Erlang::Map[:a, 1, "one", 1.0] }

    it 'formats as #<Erlang::Map #{:a=>1, "one"=>1.0}>' do
      expect(subject.inspect).to eq('#<Erlang::Map #{:a=>1, "one"=>1.0}>')
    end

    it 'has #{} in pretty_inspect' do
      expect(Erlang::Map[].pretty_inspect).to include('#{}')
      expect(Erlang::Map[Erlang::Map[], 1].pretty_inspect).to include('#{#{} => 1}')
    end
  end

  describe '#to_s' do
    subject { Erlang::Map[:a, 1, "one", 1.0] }

    it 'formats as #{:a=>1, "one"=>1.0}' do
      expect(subject.to_s).to eq('#{:a=>1, "one"=>1.0}')
    end
  end
end
