using POMDPToolbox
using POMDPs
using POMDPModels
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

    @test length(state_hist(r1)) <= steps + 1 # less than or equal because it may reach the goal too fast
    @test length(action_hist(r1)) <= steps
    @test length(reward_hist(r1)) <= steps

    for tuple in r1
        @test length(tuple) == 4
        @test isa(tuple[1], state_type(problem))
        @test isa(tuple[2], action_type(problem))
        @test isa(tuple[3], Float64)
        @test isa(tuple[4], state_type(problem))
    end

    @test length(collect(r1)) == n_steps(r1)

    hv = view(r1, 2:length(r1))
    @test n_steps(hv) == n_steps(r1)-1
    @test undiscounted_reward(r1) == undiscounted_reward(hv) + reward_hist(r1)[1]

    # iterators
    rsum = 0.0
    len = 0
    for (s, a, r, sp) in iterator(hv, (:s,:a,:r,:sp))
        @test isa(s, state_type(problem))
        @test isa(a, action_type(problem))
        @test isa(r, Float64)
        @test isa(sp, state_type(problem))
        rsum += r
        len += 1
    end
    @test len == length(hv)
    @test rsum == undiscounted_reward(hv)

    # it = iterator(hv, "(r,sp,s,a)")
    # @test eltype(collect(it)) == Tuple{Float64, state_type(problem), state_type(problem), action_type(problem)}
    tuples = collect(iterator(hv, "(r, sp, s, a)"))
    @test sum(first(t) for t in tuples) == undiscounted_reward(hv)
    tuples = collect(iterator(hv, "r,sp,s,a"))
    @test sum(first(t) for t in tuples) == undiscounted_reward(hv)
    tuples = collect(iterator(hv, "rspsa"))
    @test sum(first(t) for t in tuples) == undiscounted_reward(hv)

    #=
    function f(hv)
        rs = 0.0
        for (r,a) in HistoryIterator{typeof(hv), (:r,:a)}(hv)
            rs += r
        end
        return rs
    end
    @code_warntype f(hv)
    hi = HistoryIterator{typeof(r1), (:r,)}(r1)
    t = step_tuple(hi, 1)
    @code_warntype step_tuple(hi, 1)
    =#
end
