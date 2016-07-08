# HistoryRecorder
# maintained by @zsunberg

"""
A simulator that records the history for later examination

The simulation will be terminated when either
1) a terminal state is reached (as determined by `isterminal()` or
2) the discount factor is as small as `eps` or
3) max_steps have been executed
"""
type HistoryRecorder <: Simulator
    rng::AbstractRNG

    # these will be filled when the simulation is completed
    state_hist::AbstractVector
    action_hist::AbstractVector
    observation_hist::AbstractVector
    belief_hist::AbstractVector

    # optional: if these are null, they will be ignored
    initial_state::Nullable{Any}
    eps::Nullable{Any}
    max_steps::Nullable{Any}
    sizehint::Nullable{Integer}
end
function HistoryRecorder(;rng=MersenneTwister(rand(UInt32)),
                          initial_state=Nullable{Any}(),
                          eps=Nullable{Any}(),
                          max_steps=Nullable{Any}(),
                          sizehint=Nullable{Integer}())
    return HistoryRecorder(rng, Any[], Any[], Any[], Any[], initial_state, eps, max_steps, sizehint)
end

function simulate{S,A,O}(sim::HistoryRecorder, pomdp::POMDP{S,A,O}, policy::Policy)
    dist = initial_state_distribution(pomdp)
    bu = updater(policy)
    return simulate(sim, pomdp, policy, bu, dist)
end

function simulate{S,A,O,B}(sim::HistoryRecorder, pomdp::POMDP{S,A,O}, policy::Policy, bu::Updater{B}, initial_state_dist::AbstractDistribution)

    initial_state = get(sim.initial_state, rand(sim.rng, initial_state_dist, create_state(pomdp)))
    initial_belief = initialize_belief(bu, initial_state_dist)
    # use of deepcopy inspired from rollout.jl
    if initial_belief === initial_state_dist
      initial_belief = deepcopy(initial_belief)
    end
    eps = get(sim.eps, 0.0)
    max_steps = get(sim.max_steps, typemax(Int))
    sizehint = get(sim.sizehint, min(max_steps, 1000))

    # aliases for the histories to make the code more concise
    sh = sim.state_hist = sizehint!(Vector{S}(0), sizehint)
    ah = sim.action_hist = sizehint!(Vector{A}(0), sizehint)
    oh = sim.observation_hist = sizehint!(Vector{O}(0), sizehint)
    bh = sim.belief_hist = sizehint!(Vector{B}(0), sizehint)

    disc = 1.0
    r_total = 0.0

    push!(sh, initial_state)
    push!(bh, initial_belief)

    step = 1

    while disc > eps && !isterminal(pomdp, sh[step]) && step <= max_steps
        push!(ah, action(policy, bh[step]))

        sp, o, r = generate_sor(pomdp, sh[step], ah[step], sim.rng)

        push!(sh, sp)
        push!(oh, o)

        r_total += disc*r

        push!(bh, update(bu, bh[step], ah[step], oh[step]))

        disc *= discount(pomdp)
        step += 1
    end

    return r_total
end

function simulate{S,A}(sim::HistoryRecorder, mdp::MDP{S,A}, policy::Policy, initial_state::S=get(sim.initial_state))

    eps = get(sim.eps, 0.0)
    max_steps = get(sim.max_steps, typemax(Int))
    sizehint = get(sim.sizehint, min(max_steps, 1000))

    # aliases for the histories to make the code more concise
    sh = sim.state_hist = sizehint!(Vector{S}(0), sizehint)
    ah = sim.action_hist = sizehint!(Vector{A}(0), sizehint)
    oh = sim.observation_hist = Any[]
    bh = sim.belief_hist = Any[]

    disc = 1.0
    r_total = 0.0

    push!(sh, initial_state)

    step = 1

    while disc > eps && !isterminal(mdp, sh[step]) && step <= max_steps
        push!(ah, action(policy, sh[step]))

        sp, r = generate_sr(mdp, sh[step], ah[step], sim.rng)

        push!(sh, sp)

        r_total += disc*r

        disc *= discount(mdp)
        step += 1
    end

    return r_total
end
