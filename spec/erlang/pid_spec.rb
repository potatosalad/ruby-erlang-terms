require 'spec_helper'

describe Erlang::Pid do
  describe '#inspect' do
    subject { Erlang::Pid.new('nonode@nohost', 100, 5, 1) }

    it 'formats as #<Erlang::Pid <0.100.5> @node="nonode@nohost" @creation=1>' do
      expect(subject.inspect).to eq('#<Erlang::Pid <0.100.5> @node="nonode@nohost" @creation=1>')
    end
  end
end