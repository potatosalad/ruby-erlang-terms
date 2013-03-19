require 'spec_helper'

describe Erlang::Pid do
  describe '#inspect' do
    subject { Erlang::Pid.new('nonode@nohost', 100, 5, 1) }

    it 'formats as #<Erlang::Pid <0.100.5> @node="nonode@nohost" @creation=1>' do
      expect(subject.inspect).to eq('#<Erlang::Pid <0.100.5> @node="nonode@nohost" @creation=1>')
    end

    it 'has <0.100.5> in the pretty_inspect' do
      expect(subject.pretty_inspect).to include("<0.100.5>")
    end

    it 'compares with other pids' do
      expect(subject).to eq(subject)
      expect(subject).to eq(Erlang::Pid.new(:'nonode@nohost', 100, 5, 1))
      expect(subject).to_not eq(Erlang::Pid.new('nonode@nohost', 100, 5, 0))
    end
  end
end