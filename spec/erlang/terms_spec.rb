require 'spec_helper'

describe Erlang::Terms do
  it 'has a version number' do
    expect(Erlang::Terms::VERSION).to_not be_nil
  end
end
