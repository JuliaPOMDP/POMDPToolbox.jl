# mdp step simulator and stepthrough
let
    mdp = GridWorld()
    solver = RandomSolver(MersenneTwister(2))
    policy = solve(solver, mdp)
    sim = StepSimulator("s,sp,r,a,ai", rng=MersenneTwister(3), max_steps=100)
    n_steps = 0
    for (s, sp, r, a, ai) in simulate(sim, mdp, policy)
        @test isa(s, state_type(mdp))
        @test isa(sp, state_type(mdp))
        @test isa(r, Float64)
        @test isa(a, action_type(mdp))
        @test isa(ai, Void)
        n_steps += 1
    end
    @test n_steps <= 100

    n_steps = 0
    for s in stepthrough(mdp, policy, "s", rng=MersenneTwister(4), max_steps=100)
        @test isa(s, state_type(mdp))
        n_steps += 1
    end
    @test n_steps <= 100
end

# pomdp step simulator and stepthrough
let
    mdp = BabyPOMDP()
    policy = FeedWhenCrying()
    up = PrimedPreviousObservationUpdater(true)
    sim = StepSimulator("s,sp,r,a,b", rng=MersenneTwister(3), max_steps=100)
    n_steps = 0
    for (s, sp, r, a, b) in simulate(sim, mdp, policy, up)
        @test isa(s, state_type(mdp))
        @test isa(sp, state_type(mdp))
        @test isa(r, Float64)
        @test isa(a, action_type(mdp))
        @test isa(b, Bool)
        n_steps += 1
    end
    @test n_steps == 100

    n_steps = 0
    for r in stepthrough(mdp, policy, "r", rng=MersenneTwister(4), max_steps=100)
        @test isa(r, Float64)
        @test r <= 0
        n_steps += 1
    end
    @test n_steps == 100
end

# example from stepthrough documentation
let
    pomdp = BabyPOMDP()
    policy = RandomPolicy(pomdp)

    for (s, a, o, r, i) in stepthrough(pomdp, policy, "s,a,o,r,i", max_steps=10)
        println("in state $s")
        println("took action $o")
        println("received observation $o and reward $r")
        @assert i == nothing
    end
end
