# encoding: utf-8

require 'test_helper'

class Erlang::PidTest < Minitest::Test

  def test_create
    lhs = Erlang::Pid[:"nonode@nohost", 38, 0, 0]
    assert_equal lhs, Erlang::Pid[:"nonode@nohost", 38, 0, 0]
    assert_equal lhs, Erlang::Pid[:"nonode@nohost", 38, 0, 0, new_pid: false]
    refute_equal lhs, Erlang::Pid[:"nonode@nohost", 38, 0, 1]
    assert_equal lhs, Erlang::Pid["nonode@nohost", 38, 0, 0]
    assert_raises(ArgumentError) { Erlang::Pid[:"nonode@nohost", 38, 0, 0.0] }
    assert_raises(ArgumentError) { Erlang::Pid[Object.new, 38, 0, 0] }
  end

  def test_compare
    lhs = Erlang::Pid[:"nonode@nohost", 38, 0, 0]
    rhs = Erlang::Pid[:"nonode@nohost", 38, 0, 0]
    assert_equal 0, Erlang::Pid.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::Pid[:"nonode@nohost", 38, 0, 0]
    rhs = Erlang::Pid[:"nonode@nohost", 38, 0, 0, new_pid: false]
    assert_equal 0, Erlang::Pid.compare(lhs, rhs)
    assert lhs == rhs
    lhs = Erlang::Pid[:"nonode@nohost", 38, 0, 0]
    rhs = Erlang::Pid[:"nonode@nohost", 38, 0, 1]
    assert_equal -1, Erlang::Pid.compare(lhs, rhs)
    assert_equal 1, Erlang::Pid.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_erlang_inspect
    assert_equal "{'pid','nonode@nohost',38,0,0}", Erlang::Pid[:"nonode@nohost", 38, 0, 0].erlang_inspect
    assert_equal "{'pid','nonode@nohost',38,0,0}", Erlang.inspect(Erlang::Pid[:"nonode@nohost", 38, 0, 0])
    assert_equal "{'pid','nonode@nohost',38,0,0,'false'}", Erlang::Pid[:"nonode@nohost", 38, 0, 0, new_pid: false].erlang_inspect
    assert_equal "{'pid','nonode@nohost',38,0,0,'false'}", Erlang.inspect(Erlang::Pid[:"nonode@nohost", 38, 0, 0, new_pid: false])
  end

  def test_inspect
    assert_equal "Erlang::Pid[:\"nonode@nohost\", 38, 0, 0]", Erlang::Pid[:"nonode@nohost", 38, 0, 0].inspect
    assert_equal "Erlang::Pid[:\"nonode@nohost\", 38, 0, 0, new_pid: false]", Erlang::Pid[:"nonode@nohost", 38, 0, 0, new_pid: false].inspect
  end

  def test_property_of_inspect
    property_of {
      random_erlang_pid
    }.check { |pid|
      assert_equal pid, eval(pid.inspect)
    }
  end

  def test_marshal
    lhs = Erlang::Pid[:"nonode@nohost", 38, 0, 0]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = Erlang::Pid[:"nonode@nohost", 38, 0, 0, new_pid: false]
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(Erlang::Pid[:"nonode@nohost", 38, 0, 0], 1)
    map = map.put(Erlang::Pid[:"nonode@nohost", 38, 0, 0], 2)
    map = map.put(Erlang::Pid[:"nonode@nohost", 38, 0, 0, new_pid: false], 3)
    assert_equal 3, map[Erlang::Pid[:"nonode@nohost", 38, 0, 0]]
  end

end
