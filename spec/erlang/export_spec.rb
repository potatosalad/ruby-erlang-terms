require 'spec_helper'

describe Erlang::Export do
  describe '#inspect' do
    subject { Erlang::Export.new(:module, :function, 1) }

    it 'formats as #<Erlang::Export fun module:function/arity>' do
      expect(subject.inspect).to eq("#<Erlang::Export fun module:function/1>")
    end
  end
end
