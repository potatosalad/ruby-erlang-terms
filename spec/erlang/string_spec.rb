require 'spec_helper'

describe Erlang::String do
  describe '#inspect' do
    subject { Erlang::String.new("test") }

    it 'formats as #<Erlang::String "test">' do
      expect(subject.inspect).to eq('#<Erlang::String "test">')
    end
  end
end
