using DiscreteValueIteration

pomdp = TigerPOMDP()

mdp = UnderlyingMDP(pomdp)

@test n_states(mdp) == n_states(pomdp)
@test states(mdp) == states(pomdp)
s_mdp = rand(MersenneTwister(1), initial_state_distribution(mdp))
s_pomdp = rand(MersenneTwister(1), initial_state_distribution(pomdp))

@test s_mdp == s_pomdp

solver = ValueIterationSolver(max_iterations = 100)
mdp_policy = solve(solver, mdp, verbose=false)
pomdp_policy = solve(solver, pomdp, verbose=false)
@test mdp_policy.util == pomdp_policy.util

action_index(mdp, 1)
