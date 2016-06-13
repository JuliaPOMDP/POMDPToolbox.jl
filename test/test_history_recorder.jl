using POMDPToolbox
using POMDPModels
using GenerativeModels
using Base.Test

problem = BabyPOMDP()
policy = RandomPolicy(problem, rng=MersenneTwister(2))
steps=10
sim = HistoryRecorder(max_steps=steps, rng=MersenneTwister(3))
r1 = simulate(sim, problem, policy, updater(policy), initial_state_distribution(problem))
policy.rng = MersenneTwister(2)
sim.rng = MersenneTwister(3)
r2 = simulate(sim, problem, policy)

@test length(sim.state_hist) == steps+1
@test length(sim.action_hist) == steps
@test length(sim.observation_hist) == steps
@test length(sim.belief_hist) == steps+1
@test r1 == r2

println("Test 1 Done")

problem = GridWorld()
policy = RandomPolicy(problem, rng=MersenneTwister(2))
steps=10
sim = HistoryRecorder(max_steps=steps, rng=MersenneTwister(3))
r1 = simulate(sim, problem, policy, initial_state(problem, sim.rng))

@test length(sim.state_hist) <= steps+1 # less than or equal because it may reach the goal too fast
@test length(sim.action_hist) <= steps
@test length(sim.observation_hist) == 0
@test length(sim.belief_hist) == 0

