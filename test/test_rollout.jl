using POMDPToolbox
using POMDPModels
using GenerativeModels

let
    problem = BabyPOMDP()
    solver = RandomSolver(rng=MersenneTwister(1))
    policy = solve(solver, problem)
    sim = RolloutSimulator(max_steps=10)
    simulate(sim, problem, policy, updater(policy), initial_state_distribution(problem))

    problem = GridWorld()
    solver = RandomSolver(rng=MersenneTwister(1))
    policy = solve(solver, problem)
    sim = RolloutSimulator(max_steps=10)
    simulate(sim, problem, policy, initial_state(problem, sim.rng))
end
