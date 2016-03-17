


# TODO: There should be a common interface for things like setting the initial belief, state, max_steps, etc.


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
    initial_state
    eps
    max_steps
end
function HistoryRecorder(;rng=MersenneTwister(rand(UInt32)),
                          initial_state=nothing,
                          eps=nothing,
                          max_steps=nothing)
    return HistoryRecorder(rng, Any[], Any[], Any[], Any[], initial_state, eps, max_steps)
end

function simulate(sim::HistoryRecorder, pomdp::POMDP, policy::Policy, bu::BeliefUpdater, initial_belief::Belief)

    if sim.initial_state == nothing
        sim.initial_state = create_state(pomdp)
        rand!(sim.rng, sim.initial_state, initial_belief)
    end
    if sim.eps == nothing
        sim.eps = 0.0
    end
    if sim.max_steps == nothing
        sim.max_steps = Inf
    end

    # aliases for the histories to make the code more concise
    sh = sim.state_hist = Any[]
    ah = sim.action_hist = Any[]
    oh = sim.observation_hist = Any[]
    bh = sim.belief_hist = Any[]
   
    disc = 1.0
    r = 0.0

    push!(sh, sim.initial_state)
    push!(bh, initial_belief)

    obs_dist = create_observation_distribution(pomdp)
    trans_dist = create_transition_distribution(pomdp)

    step = 1

    while disc > sim.eps && !isterminal(pomdp, sh[step]) && step <= sim.max_steps
        push!(ah, action(policy, bh[step]))

        push!(sh, create_state(pomdp))
        trans_dist = transition(pomdp, sh[step], ah[step], trans_dist)
        rand!(sim.rng, sh[step+1], trans_dist)

        r += disc*reward(pomdp, sh[step], ah[step], sh[step+1])

        push!(oh, create_observation(pomdp))
        obs_dist = observation(pomdp, sh[step], ah[step], sh[step+1], obs_dist)
        rand!(sim.rng, oh[step], obs_dist)

        push!(bh, update(bu, bh[step], ah[step], oh[step]))

        disc *= discount(pomdp)
        step += 1
    end

    return r
end
