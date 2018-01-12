using POMDPModels
using POMDPToolbox

let
    rng = MersenneTwister(7)

    mdp = GridWorld()
    s = initial_state(mdp, rng)
    a = rand(rng, actions(mdp))
    @inferred generate_sri(mdp, s, a, rng)

    pomdp = TigerPOMDP()
    s = initial_state(pomdp, rng)
    a = rand(rng, actions(pomdp))
    @inferred generate_sori(pomdp, s, a, rng)

    policy = RandomPolicy(pomdp, rng=rng)
    @inferred action_info(policy, s)

    solver = RandomSolver(rng=rng)
    policy, sinfo = solve_info(solver, pomdp)
    @test isa(sinfo, Void)

    up = updater(policy)
    d = initial_state_distribution(pomdp)
    b = initialize_belief(up, d)
    a = action(policy, b)
    sp, o = generate_so(pomdp, rand(rng, d), a, rng)
    @inferred update_info(up, b, a, o)
end
