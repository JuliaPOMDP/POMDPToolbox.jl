using POMDPToolbox
using POMDPModels
using Base.Test

let
    problem = BabyPOMDP()

    solver = RandomSolver(rng=MersenneTwister(1))

    policy = solve(solver, problem)

    sim = RolloutSimulator(max_steps=10, rng=MersenneTwister(1))

    r = simulate(sim, problem, policy, updater(policy), initial_state_distribution(problem))

    @test_approx_eq_eps r -27.27829 1e-3
end
