using POMDPToolbox
using POMDPModels
using GenerativeModels
using Base.Test

let
    problem = BabyPOMDP()
    policy = RandomPolicy(problem, rng=MersenneTwister(2))
    steps=10
    sim = HistoryRecorder(max_steps=steps, rng=MersenneTwister(3))
    @show_requirements simulate(sim, problem, policy, updater(policy), initial_state_distribution(problem))
    r1 = simulate(sim, problem, policy, updater(policy), initial_state_distribution(problem))
    policy.rng = MersenneTwister(2)
    sim.rng = MersenneTwister(3)
    r2 = simulate(sim, problem, policy)

    @test length(state_hist(r1)) == steps+1
    @test length(action_hist(r1)) == steps
    @test length(observation_hist(r1)) == steps
    @test length(belief_hist(r1)) == steps+1
    @test length(state_hist(r2)) == steps+1
    @test length(action_hist(r2)) == steps
    @test length(observation_hist(r2)) == steps
    @test length(belief_hist(r2)) == steps+1

    @test isnull(exception(r1))
    @test isnull(exception(r2))
    @test isnull(backtrace(r1))
    @test isnull(backtrace(r2))

    @test n_steps(r1) == n_steps(r2)
    @test undiscounted_reward(r1) == undiscounted_reward(r2)
    @test discounted_reward(r1) == discounted_reward(r2)

    @test length(collect(r1)) == n_steps(r1)
    @test length(collect(r2)) == n_steps(r2)

    for tuple in r1
        length(tuple) == 6
    end

    problem = GridWorld()
    policy = RandomPolicy(problem, rng=MersenneTwister(2))
    steps=10
    sim = HistoryRecorder(max_steps=steps, rng=MersenneTwister(3))
    @show_requirements simulate(sim, problem, policy, initial_state(problem, sim.rng))
    r1 = simulate(sim, problem, policy, initial_state(problem, sim.rng))

    @test length(state_hist(r1)) <= steps+1 # less than or equal because it may reach the goal too fast
    @test length(action_hist(r1)) <= steps
    @test length(reward_hist(r1)) <= steps

    for tuple in r1
        length(tuple) == 4
        isa(tuple[1], state_type(problem))
        isa(tuple[2], action_type(problem))
        isa(tuple[3], Float64)
        isa(tuple[4], state_type(problem))
    end

    @test length(collect(r1)) == n_steps(r1)
end
