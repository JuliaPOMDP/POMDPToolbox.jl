# RolloutSimulator
# maintained by @zsunberg

"""
a fast simulator that just returns the reward
"""
type RolloutSimulator <: Simulator
    rng::AbstractRNG

    # optional: if these are null, they will be ignored
    initial_state::Nullable{Any}
    eps::Nullable{Float64}
    max_steps::Nullable{Int}
end
RolloutSimulator(rng::AbstractRNG) = RolloutSimulator(rng, Nullable{Any}(), Nullable{Float64}(), Nullable{Int}())
RolloutSimulator() = RolloutSimulator(MersenneTwister(rand(UInt32)))
function RolloutSimulator(;rng=MersenneTwister(rand(UInt32)),
                           initial_state=Nullable{Any}(),
                           eps=Nullable{Float64}(),
                           max_steps=Nullable{Int}())
    return RolloutSimulator(rng, initial_state, eps, max_steps)
end

"""
Return the reward for a single simulation of the pomdp.

The simulation will be terminated when either
1) a terminal state is reached (as determined by `isterminal()` or
2) the discount factor is as small as `eps` or
3) max_steps have been executed
"""
function simulate{S,A,O}(sim::RolloutSimulator, pomdp::POMDP{S,A,O}, policy::Policy, updater::BeliefUpdater, initial_belief::Belief)

    s = get(sim.initial_state, rand(sim.rng, initial_belief))
    eps = get(sim.eps, 0.0)
    max_steps = get(sim.max_steps, typemax(Int))

    disc = 1.0
    r = 0.0

    # I think this deepcopy is necessary because the memory will be reused
    b = deepcopy(initial_belief)
    a = A()
    sp = S()
    o = O()

    obs_dist = create_observation_distribution(pomdp)
    trans_dist = create_transition_distribution(pomdp)
    bp = create_belief(updater)
    step = 1

    while disc > eps && !isterminal(pomdp, s) && step <= max_steps # TODO also check for terminal observation
        a = action(policy, b, a)

        trans_dist = transition(pomdp, s, a, trans_dist)
        sp = rand(sim.rng, trans_dist, sp)

        r += disc*reward(pomdp, s, a, sp)

        obs_dist = observation(pomdp, s, a, sp, obs_dist)
        o = rand(sim.rng, obs_dist, o)

        # alternates using the memory allocated for s and sp so nothing new has to be allocated
        tmp = s
        s = sp
        sp = tmp

        bp = update(updater, b, a, o, bp)
        tmpb = b
        b = bp
        bp = tmpb

        disc *= discount(pomdp)
        step += 1
    end

    return r
end

