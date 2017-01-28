# HistoryRecorder
# maintained by @zsunberg

"""
A simulator that records the history for later examination

The simulation will be terminated when either
1) a terminal state is reached (as determined by `isterminal()` or
2) the discount factor is as small as `eps` or
3) max_steps have been executed

Other options
    capture_exception::Bool

    show_progress::Bool
        show a progress bar for the simulation
"""
type HistoryRecorder <: Simulator
    rng::AbstractRNG

    # options
    capture_exception::Bool
    show_progress::Bool

    # optional: if these are null, they will be ignored
    initial_state::Nullable{Any}
    eps::Nullable{Any}
    max_steps::Nullable{Any}
    sizehint::Nullable{Integer}

    # ALL FIELDS BELOW ARE DEPRECATED
    # Instead, use the fields in the SimHistory object returned by simulate
    # these fields will be deleted on 
    state_hist::AbstractVector
    action_hist::AbstractVector
    observation_hist::AbstractVector
    belief_hist::AbstractVector
    reward_hist::Vector{Float64}

    # if capture_exception is true and there is an exception, it will be stored here
    exception::Nullable{Exception}
    backtrace::Nullable{Any}

    HistoryRecorder(rng, capture_exception, show_progress, initial_state,
                    eps, max_steps, sizehint) = new(rng, capture_exception, show_progress, initial_state,
                                                    eps, max_steps, sizehint,
                                                    Any[], Any[], Any[], Any[], Float64[], nothing, nothing)
end
function HistoryRecorder(;rng=MersenneTwister(rand(UInt32)),
                          initial_state=Nullable{Any}(),
                          eps=Nullable{Any}(),
                          max_steps=Nullable{Any}(),
                          sizehint=Nullable{Integer}(),
                          capture_exception=false,
                          show_progress=false)
    return HistoryRecorder(rng, capture_exception, show_progress, initial_state, eps, max_steps, sizehint)
end

@POMDP_require simulate(sim::HistoryRecorder, pomdp::POMDP, policy::Policy) begin
    @req updater(::typeof(policy))
    up = updater(policy)
    @subreq simulate(sim, pomdp, policy, up)
end

@POMDP_require simulate(sim::HistoryRecorder, pomdp::POMDP, policy::Policy, bu::Updater) begin
    @req initial_state_distribution(::typeof(pomdp))
    dist = initial_state_distribution(pomdp)
    @subreq simulate(sim, pomdp, policy, bu, dist)
end

function simulate(sim::HistoryRecorder, pomdp::POMDP, policy::Policy, bu::Updater=updater(policy))
    dist = initial_state_distribution(pomdp)
    return simulate(sim, pomdp, policy, bu, dist)
end

@POMDP_require simulate(sim::HistoryRecorder, pomdp::POMDP, policy::Policy, bu::Updater, dist::Any) begin
    P = typeof(pomdp)
    S = state_type(pomdp)
    A = action_type(pomdp)
    O = obs_type(pomdp)
    if isnull(sim.initial_state)
        @req rand(::typeof(sim.rng), ::typeof(dist))
    end
    @req initialize_belief(::typeof(bu), ::typeof(dist))
    @req isterminal(::P, ::S)
    @req discount(::P)
    @req generate_sor(::P, ::S, ::A, ::typeof(sim.rng))
    b = initialize_belief(bu, dist)
    B = typeof(b)
    @req action(::typeof(policy), ::B)
    @req update(::typeof(bu), ::B, ::A, ::O)
end

function simulate{S,A,O,B}(sim::HistoryRecorder,
                           pomdp::POMDP{S,A,O}, 
                           policy::Policy,
                           bu::Updater{B},
                           initial_state_dist::Any)

    initial_state = get_initial_state(sim, initial_state_dist)
    initial_belief = initialize_belief(bu, initial_state_dist)
    # use of deepcopy inspired from rollout.jl
    if initial_belief === initial_state_dist
        initial_belief = deepcopy(initial_belief)
    end
    max_steps = get(sim.max_steps, typemax(Int))
    if !isnull(sim.eps)
        max_steps = min(max_steps, ceil(Int,log(get(sim.eps))/log(discount(pomdp))))
    end
    sizehint = get(sim.sizehint, min(max_steps, 1000))

    # aliases for the histories to make the code more concise
    sh = sim.state_hist = sizehint!(Vector{S}(0), sizehint)
    ah = sim.action_hist = sizehint!(Vector{A}(0), sizehint)
    oh = sim.observation_hist = sizehint!(Vector{O}(0), sizehint)
    bh = sim.belief_hist = sizehint!(Vector{B}(0), sizehint)
    rh = sim.reward_hist = sizehint!(Vector{Float64}(0), sizehint)

    push!(sh, initial_state)
    push!(bh, initial_belief)

    if sim.show_progress
        prog = Progress(max_steps, "Simulating..." )
    end

    disc = 1.0
    step = 1

    try
        while !isterminal(pomdp, sh[step]) && step <= max_steps
            push!(ah, action(policy, bh[step]))

            sp, o, r = generate_sor(pomdp, sh[step], ah[step], sim.rng)

            push!(sh, sp)
            push!(oh, o)
            push!(rh, r)

            push!(bh, update(bu, bh[step], ah[step], oh[step]))

            step += 1

            if sim.show_progress
                next!(prog)
            end
        end
    catch ex
        if sim.capture_exception
            sim.exception = ex
            sim.backtrace = catch_backtrace()
        else
            rethrow(ex)
        end
    end

    return POMDPHistory(sh, ah, oh, bh, rh, discount(pomdp), sim.exception, sim.backtrace)
end

@POMDP_require simulate(sim::HistoryRecorder, mdp::MDP, policy::Policy) begin
    if isnull(sim.initial_state)
        @req initial_state(::typeof(mdp), ::typeof(sim.rng))
    end
    init_state = get(sim.initial_state, initial_state(mdp, sim.rng))
    @subreq simulate(sim, mdp, policy, init_state)
end

@POMDP_require simulate(sim::HistoryRecorder, mdp::MDP, policy::Policy, initial_state::Any) begin
    P = typeof(mdp)
    S = state_type(mdp)
    A = action_type(mdp)
    @req isterminal(::P, ::S)
    @req action(::typeof(policy), ::S)
    @req generate_sr(::P, ::S, ::A, ::typeof(sim.rng))
    @req discount(::P)
end

function simulate{S,A}(sim::HistoryRecorder,
                       mdp::MDP{S,A}, policy::Policy,
                       init_state::S=get_initial_state(sim, mdp))

    max_steps = get(sim.max_steps, typemax(Int))
    if !isnull(sim.eps)
        max_steps = min(max_steps, ceil(Int,log(get(sim.eps))/log(discount(mdp))))
    end
    sizehint = get(sim.sizehint, min(max_steps, 1000))

    # aliases for the histories to make the code more concise
    sh = sim.state_hist = sizehint!(Vector{S}(0), sizehint)
    ah = sim.action_hist = sizehint!(Vector{A}(0), sizehint)
    oh = sim.observation_hist = Any[]
    bh = sim.belief_hist = Any[]
    rh = sim.reward_hist = sizehint!(Vector{Float64}(0), sizehint)

    if sim.show_progress
        prog = Progress(max_steps, "Simulating..." )
    end

    push!(sh, init_state)

    disc = 1.0
    step = 1

    try
        while !isterminal(mdp, sh[step]) && step <= max_steps
            push!(ah, action(policy, sh[step]))

            sp, r = generate_sr(mdp, sh[step], ah[step], sim.rng)

            push!(sh, sp)
            push!(rh, r)

            disc *= discount(mdp)
            step += 1

            if sim.show_progress
                next!(prog)
            end
        end
    catch ex
        if sim.capture_exception
            sim.exception = ex
            sim.backtrace = catch_backtrace()
        else
            rethrow(ex)
        end
    end

    return MDPHistory(sh, ah, rh, discount(mdp), sim.exception, sim.backtrace)
end

function get_initial_state(sim::HistoryRecorder, initial_state_dist)
    if isnull(sim.initial_state)
        return rand(sim.rng, initial_state_dist)
    else
        return get(sim.initial_state)
    end
end

function get_initial_state(sim::HistoryRecorder, mdp::Union{MDP,POMDP})
    if isnull(sim.initial_state)
        return initial_state(mdp, sim.rng)
    else
        return get(sim.initial_state)
    end
end
