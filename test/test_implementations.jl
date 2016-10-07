
type TestMDP <: MDP{Bool, Bool} end
type TestPOMDP <: POMDP{Bool, Bool, Bool} end

@test actions(TestMDP()) == (true, false)
@test actions(TestPOMDP()) == (true, false)

a = [1,2,3]
@test iterator(a) == a
@test iterator((1,2,3)) == (1,2,3)

@test states(TestMDP()) == (true, false)
@test states(TestPOMDP()) == (true, false)

@test state_index(TestMDP(), 1) == 1
@test action_index(TestMDP(), 2) == 2
@test obs_index(TestMDP(), 3) == 3