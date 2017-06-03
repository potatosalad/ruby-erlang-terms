# encoding: utf-8

require 'test_helper'

class Erlang::FunctionTest < Minitest::Test

  def test_create
    lhs = new_function
    assert_equal lhs, new_function
    refute_equal lhs, old_function
    lhs = old_function
    assert_equal lhs, old_function
    refute_equal lhs, new_function
    assert_raises(ArgumentError) { Erlang::Function[mod: :test, free_vars: [], arity: Object.new] }
  end

  def test_compare
    lhs = new_function
    rhs = new_function
    assert_equal 0, Erlang::Function.compare(lhs, rhs)
    assert lhs == rhs
    lhs = new_function
    rhs = old_function
    assert_equal -1, Erlang::Function.compare(lhs, rhs)
    assert_equal 1, Erlang::Function.compare(rhs, lhs)
    assert lhs < rhs
    assert rhs > lhs
  end

  def test_new_function
    a = new_function
    b = old_function
    assert a.new_function?
    refute b.new_function?
  end

  def test_erlang_inspect
    lhs = "{'function',0,131917954694080383981903414123034120242,20,'erl_eval',20,52032458,{'pid','nonode@nohost',79,0,0},[{[],'none','none',[{'clause',27,[],[],[{'atom',0,'ok'}]}]}]}"
    assert_equal lhs, new_function.erlang_inspect
    lhs = "{'function',{'pid','nonode@nohost',38,0,0},'erl_eval',20,95849314,[[{'B',<<131,114,0,3,100,0,13,110,111,110,111,100,101,64,110,111,104,111,115,116,0,0,0,0,122,0,0,0,0,0,0,0,0>>},{'L',\"\\x83r\\x00\\x03d\\x00\\rnonode@nohost\\x00\\x00\\x00\\x00z\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\"},{'R',{'reference','nonode@nohost',0,[122,0,0]}}],[{'clause',1,[],[],[{'integer',1,1}]}],{'eval',{'shell','local_func'},[{'pid','nonode@nohost',22,0,0}]}]}"
    assert_equal lhs, old_function.erlang_inspect
  end

  def test_inspect
    lhs = "Erlang::Function[arity: 0, uniq: 131917954694080383981903414123034120242, index: 20, mod: :erl_eval, old_index: 20, old_uniq: 52032458, pid: Erlang::Pid[:\"nonode@nohost\", 79, 0, 0], free_vars: [Erlang::Tuple[[], :none, :none, [Erlang::Tuple[:clause, 27, [], [], [Erlang::Tuple[:atom, 0, :ok]]]]]]]"
    assert_equal lhs, new_function.inspect
    assert_equal new_function, eval(lhs)
    lhs = "Erlang::Function[pid: Erlang::Pid[:\"nonode@nohost\", 38, 0, 0], mod: :erl_eval, index: 20, uniq: 95849314, free_vars: [[Erlang::Tuple[:B, \"\\x83r\\x00\\x03d\\x00\\rnonode@nohost\\x00\\x00\\x00\\x00z\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\"], Erlang::Tuple[:L, Erlang::String[\"\\x83r\\x00\\x03d\\x00\\rnonode@nohost\\x00\\x00\\x00\\x00z\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\"]], Erlang::Tuple[:R, Erlang::Reference[:\"nonode@nohost\", 0, [122, 0, 0]]]], [Erlang::Tuple[:clause, 1, [], [], [Erlang::Tuple[:integer, 1, 1]]]], Erlang::Tuple[:eval, Erlang::Tuple[:shell, :local_func], [Erlang::Pid[:\"nonode@nohost\", 22, 0, 0]]]]]"
    assert_equal lhs, old_function.inspect
    assert_equal old_function, eval(lhs)
  end

  def test_marshal
    lhs = new_function
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
    lhs = old_function
    rhs = Marshal.load(Marshal.dump(lhs))
    assert_equal lhs, rhs
  end

  def test_equivalence
    map = Erlang::Map[]
    map = map.put(new_function, 1)
    map = map.put(new_function, 2)
    assert_equal 2, map[new_function]
    map = Erlang::Map[]
    map = map.put(old_function, 1)
    map = map.put(old_function, 2)
    assert_equal 2, map[old_function]
  end

private
  def new_function
    return Erlang::Function[
      arity: 0,
      uniq: "c>yRz_\xF6\xED?Hv(\x04\x19\x102",
      index: 20,
      mod: :erl_eval,
      old_index: 20,
      old_uniq: 52032458,
      pid: Erlang::Pid[:"nonode@nohost", 79, 0, 0],
      free_vars: Erlang::List[
        Erlang::Tuple[
          Erlang::Nil,
          :none,
          :none,
          Erlang::List[
            Erlang::Tuple[
              :clause,
              27,
              Erlang::Nil,
              Erlang::Nil,
              Erlang::List[Erlang::Tuple[:atom, 0, :ok]]
            ]
          ]
        ]
      ]
    ]
  end

  def old_function
    return Erlang::Function[
      pid: Erlang::Pid[:"nonode@nohost", 38, 0, 0],
      mod: :erl_eval,
      index: 20,
      uniq: 95849314,
      free_vars: Erlang::List[
        Erlang::List[
          Erlang::Tuple[
            :B,
            Erlang::Binary[131,114,0,3,100,0,13,110,111,110,111,100,101,64,110,111,104,111,115,116,0,0,0,0,122,0,0,0,0,0,0,0,0]
          ],
          Erlang::Tuple[
            :L,
            Erlang::String[131,114,0,3,100,0,13,110,111,110,111,100,101,64,110,111,104,111,115,116,0,0,0,0,122,0,0,0,0,0,0,0,0]
          ],
          Erlang::Tuple[
            :R,
            Erlang::Reference[:"nonode@nohost", 0, [122, 0, 0]]
          ]
        ],
        Erlang::List[
          Erlang::Tuple[
            :clause,
            1,
            Erlang::Nil,
            Erlang::Nil,
            Erlang::List[Erlang::Tuple[:integer, 1, 1]]
          ]
        ],
        Erlang::Tuple[
          :eval,
          Erlang::Tuple[:shell, :local_func],
          Erlang::List[Erlang::Pid[:"nonode@nohost", 22, 0, 0]]
        ]
      ]
    ]
  end

end
