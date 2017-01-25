using POMDPToolbox
using POMDPModels
using GenerativeModels
using Base.Test

let
    problem = BabyPOMDP()
    solver = RandomSolver(rng=MersenneTwister(1))
    policy = solve(solver, problem)
    sim = RolloutSimulator(max_steps=10, rng=MersenneTwister(1))
    r1 = simulate(sim, problem, policy, updater(policy), initial_state_distribution(problem))

    problem = GridWorld()
    solver = RandomSolver(rng=MersenneTwister(1))
    policy = solve(solver, problem)
    sim = RolloutSimulator(max_steps=10, rng=MersenneTwister(1))
    r2 = simulate(sim, problem, policy, initial_state(problem, sim.rng))

    @test_approx_eq_eps r1 -27.27829 1e-3
    @test_approx_eq_eps r2 0.0 1e-3
end
