
# TODO: There should be a common interface for things like setting the initial belief, state, max_steps, etc.

# a fast simulator that just returns the reward
type RolloutSimulator <: Simulator
    rng::AbstractRNG

    # optional: if these are nothing, they will be ignored
    initial_belief
    initial_state
    eps
    max_steps
end
RolloutSimulator(rng::AbstractRNG) = RolloutSimulator(rng, nothing, nothing, nothing, nothing)
RolloutSimulator() = RolloutSimulator(MersenneTwister(rand(Uint32)))
function RolloutSimulator(;rng=MersenneTwister(rand(Uint32)),
                           initial_belief=nothing,
                           initial_state=nothing,
                           eps=nothing,
                           max_steps=nothing)
    return RolloutSimulator(rng, initial_belief, initial_state, eps, max_steps)
end

#=
Return the reward for a single simulation of the pomdp.

The simulation will be terminated when either
1) a terminal state is reached (as determined by `isterminal()` or
2) the discount factor is as small as `eps` or
3) max_steps have been executed
=#
function simulate(sim::RolloutSimulator,
                  pomdp::POMDP,
                  policy::Policy)

    
    if sim.initial_belief == nothing
        sim.initial_belief = initial_belief(pomdp)
    end
    if sim.initial_state == nothing
        sim.initial_state = create_state(pomdp)
        rand!(sim.rng, sim.initial_state, sim.initial_belief)
    end
    if sim.eps == nothing
        sim.eps = 0.0
    end
    if sim.max_steps == nothing
        sim.max_steps = Inf
    end

    disc = 1.0
    r = 0.0
    s = deepcopy(sim.initial_state)
    b = deepcopy(sim.initial_belief)

    obs_dist = create_observation_distribution(pomdp)
    trans_dist = create_transition_distribution(pomdp)
    sp = create_state(pomdp)
    o = create_observation(pomdp)
    a = create_action(pomdp)
    bp = deepcopy(sim.initial_belief)
    step = 1

    while disc > sim.eps && !isterminal(pomdp, s) && step <= sim.max_steps
        a = action(pomdp, policy, b, a)
        r += disc*reward(pomdp, s, a)

        trans_dist = transition(pomdp, s, a, trans_dist)
        rand!(sim.rng, sp, trans_dist)

        obs_dist = observation(pomdp, sp, a, obs_dist)
        rand!(sim.rng, o, obs_dist)

        # alternates using the memory allocated for s and sp so nothing new has to be allocated
        tmp = s
        s = sp
        sp = tmp

        bp = belief(pomdp, b, a, o, bp)
        tmpb = b
        b = bp
        bp = tmpb

        disc *= discount(pomdp)
        step += 1
    end

    return r
end

# a slower (because of variable length arrays) simulator
# that records the history for later examination
type HistoryRecorder <: Simulator
    rng::AbstractRNG

    # these will be filled when the simulation is completed
    state_hist::Vector{Any}
    action_hist::Vector{Any}
    observation_hist::Vector{Any}
    belief_hist::Vector{Any}

    # optional: if these are nothing, they will be ignored
    initial_belief
    initial_state
    eps
    max_steps
end
function HistoryRecorder(;rng=MersenneTwister(rand(Uint32)),
                          initial_belief=nothing,
                          initial_state=nothing,
                          eps=nothing,
                          max_steps=nothing)
    return HistoryRecorder(rng, {}, {}, {}, {}, initial_belief, initial_state, eps, max_steps)
end

function simulate(sim::HistoryRecorder,
                  pomdp::POMDP,
                  policy::Policy)

    if sim.initial_belief == nothing
        sim.initial_belief = initial_belief(pomdp)
    end
    if sim.initial_state == nothing
        sim.initial_state = create_state(pomdp)
        rand!(sim.rng, sim.initial_state, sim.initial_belief)
    end
    if sim.eps == nothing
        sim.eps = 0.0
    end
    if sim.max_steps == nothing
        sim.max_steps = Inf
    end

    # aliases for the histories to make the code more concise
    sh = sim.state_hist = {}
    ah = sim.action_hist = {}
    oh = sim.observation_hist = {}
    bh = sim.belief_hist = {}
   
    disc = 1.0
    r = 0.0

    push!(sim.state_hist, deepcopy(sim.initial_state))
    push!(sim.belief_hist, deepcopy(sim.initial_belief))

    obs_dist = create_observation_distribution(pomdp)
    trans_dist = create_transition_distribution(pomdp)

    step = 1

    while disc > sim.eps && !isterminal(pomdp, sh[step]) && step <= sim.max_steps
        push!(ah, create_action(pomdp))
        ah[step] = action(pomdp, policy, bh[step], ah[step])
        r += disc*reward(pomdp, sh[step], ah[step])

        push!(sh, create_state(pomdp))
        trans_dist = transition(pomdp, sh[step], ah[step], trans_dist)
        rand!(sim.rng, sh[step+1], trans_dist)

        push!(oh, create_observation(pomdp))
        obs_dist = observation(pomdp, sh[step+1], ah[step], obs_dist)
        rand!(sim.rng, oh[step], obs_dist)

        push!(bh, create_belief(pomdp))
        bh[step+1] = belief(pomdp, bh[step], ah[step], oh[step], bh[step+1])

        disc *= discount(pomdp)
        step += 1
    end

    return r
end
