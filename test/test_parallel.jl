using POMDPToolbox
using POMDPModels

let
    pomdp = BabyPOMDP()
    fwc = FeedWhenCrying()
    rnd = solve(RandomSolver(MersenneTwister(7)), pomdp)

    q = []
    push!(q, Sim(pomdp, fwc, max_steps=32, rng=MersenneTwister(4), metadata=Dict(:policy=>"feed when crying")))
    push!(q, Sim(pomdp, fwc, max_steps=32, rng=MersenneTwister(4), metadata=Dict(:policy=>"feed when crying")))
    push!(q, Sim(pomdp, rnd, max_steps=32, rng=MersenneTwister(4), metadata=Dict(:policy=>"random")))

    println("There should be a warning here:")
    run_parallel(q)

    procs = addprocs(1)
    @everywhere using POMDPToolbox
    @everywhere using POMDPModels
    println("There should not be a warning here:")
    @show run_parallel(q) do sim, hist
        return [:steps=>n_steps(hist), :reward=>discounted_reward(hist)]
    end

    @show data = run_parallel(q)
    @test data[1, :reward] == data[2, :reward]
    @test var(data[:reward][1:2]) == 0.0
    rmprocs(procs)

    mdp = GridWorld()
    q = []
    push!(q, Sim(mdp, RandomPolicy(mdp), max_steps=100))
    run(q)
end

# example from readme
let
    using POMDPToolbox
    using POMDPModels

    pomdp = BabyPOMDP()
    fwc = FeedWhenCrying()
    rnd = solve(RandomSolver(MersenneTwister(7)), pomdp)

    q = [] # vector of the simulations to be run
    push!(q, Sim(pomdp, fwc, max_steps=32, rng=MersenneTwister(4), metadata=Dict(:policy=>"feed when crying")))
    push!(q, Sim(pomdp, rnd, max_steps=32, rng=MersenneTwister(4), metadata=Dict(:policy=>"random")))

    # this creates two simulations, one with the feed-when-crying policy and one with a random policy

    data = run_parallel(q)

    # by default, the dataframe output contains the reward and the contents of `metadata`
    @show data
    # data = 2×2 DataFrames.DataFrame
    # │ Row │ policy             │ reward   │
    # ├─────┼────────────────────┼──────────┤
    # │ 1   │ "feed when crying" │ -4.5874  │
    # │ 2   │ "random"           │ -27.4139 │

    # to perform additional analysis on each of the simulations one can define a processing function with the `do` syntax:
    data2 = run_parallel(q, progress=false) do sim, hist
        println("finished a simulation - final state was $(last(state_hist(hist)))")
        return [:steps=>n_steps(hist), :reward=>discounted_reward(hist)]
    end

    @show data2
    # 2×3 DataFrames.DataFrame
    # │ Row │ policy             │ reward   │ steps │
    # ├─────┼────────────────────┼──────────┼───────┤
    # │ 1   │ "feed when crying" │ -18.2874 │ 32.0  │
    # │ 2   │ "random"           │ -17.7054 │ 32.0  │
end
