using POMDPToolbox
using POMDPModels

problem = BabyPOMDP()

solver = RandomSolver(rng=MersenneTwister(1))

policy = solve(solver, problem)

sim = RolloutSimulator(max_steps=10)

simulate(sim, problem, policy, updater(policy), initial_state_distribution(problem))
