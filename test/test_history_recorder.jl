using POMDPs
using POMDPToolbox
using POMDPModels

problem = BabyPOMDP()

policy = RandomPolicy(problem, rng=MersenneTwister(2))

steps=10

sim = HistoryRecorder(max_steps=steps)

simulate(sim, problem, policy, updater(policy), initial_belief(problem))

@test length(sim.state_hist) == steps+1
@test length(sim.action_hist) == steps
@test length(sim.observation_hist) == steps
@test length(sim.belief_hist) == steps+1
