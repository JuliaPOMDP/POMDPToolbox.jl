using POMDPToolbox
using POMDPModels
using Base.Test

let
    problem = BabyPOMDP()
    solver = RandomSolver(rng=MersenneTwister(1))
    policy = solve(solver, problem)
    sim = RolloutSimulator(max_steps=10, rng=MersenneTwister(1))
    r1 = @inferred simulate(sim, problem, policy, updater(policy), initial_state_distribution(problem))

    sim = RolloutSimulator(max_steps=10, rng=MersenneTwister(1), initial_state=true)
    dummy = @inferred simulate(sim, problem, policy, updater(policy), nothing)

    problem = GridWorld()
    solver = RandomSolver(rng=MersenneTwister(1))
    policy = solve(solver, problem)
    sim = RolloutSimulator(max_steps=10, rng=MersenneTwister(1))
    r2 = @inferred simulate(sim, problem, policy, initial_state(problem, sim.rng))

    @test isapprox(r1, -27.27829, atol=1e-3)
    @test isapprox(r2, 0.0, atol=1e-3)
end
