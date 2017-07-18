# RolloutSimulator
# maintained by @zsunberg

"""
A fast simulator that just returns the reward

The simulation will be terminated when either
1) a terminal state is reached (as determined by `isterminal()` or
2) the discount factor is as small as `eps` or
3) max_steps have been executed

Keyword arguments are:

    initial_state
    
    eps

    max_steps
"""
struct RolloutSimulator{RNG<:AbstractRNG} <: Simulator
    rng::RNG

    # optional: if these are null, they will be ignored
    initial_state::Nullable{Any}
    eps::Nullable{Float64}
    max_steps::Nullable{Int}
end
RolloutSimulator(rng::AbstractRNG) = RolloutSimulator(rng, Nullable{Any}(), Nullable{Float64}(), Nullable{Int}())
function RolloutSimulator(;rng=MersenneTwister(rand(UInt32)),
                           initial_state=Nullable{Any}(),
                           eps=Nullable{Float64}(),
                           max_steps=Nullable{Int}())
    return RolloutSimulator{typeof(rng)}(rng, initial_state, eps, max_steps)
end

@POMDP_require simulate(sim::RolloutSimulator, pomdp::POMDP, policy::Policy) begin
    @req updater(::typeof(policy))
    bu = updater(policy)
    @subreq simulate(sim, pomdp, policy, bu)
end

@POMDP_require simulate(sim::RolloutSimulator, pomdp::POMDP, policy::Policy, bu::Updater) begin
    @req initial_state_distribution(::typeof(pomdp))
    dist = initial_state_distribution(pomdp)
    @subreq simulate(sim, pomdp, policy, bu, dist)
end

function simulate(sim::RolloutSimulator, pomdp::POMDP, policy::Policy, bu::Updater=updater(policy))
    dist = initial_state_distribution(pomdp)
    return simulate(sim, pomdp, policy, bu, dist)
end

@POMDP_require simulate(sim::RolloutSimulator, pomdp::POMDP, policy::Policy, updater::Updater, initial_belief) begin
    P = typeof(pomdp)
    S = state_type(P)
    A = action_type(P)
    O = obs_type(P)
    @req rand(::typeof(sim.rng), ::typeof(initial_belief))
    @req initialize_belief(::typeof(updater), ::typeof(initial_belief))
    @req isterminal(::P, ::S)
    @req discount(::P)
    @req generate_sor(::P, ::S, ::A, ::typeof(sim.rng))
    b = initialize_belief(updater, initial_belief)
    @req action(::typeof(policy), ::typeof(b))
    @req update(::typeof(updater), ::typeof(b), ::A, ::O)
end


function simulate{S}(sim::RolloutSimulator, pomdp::POMDP{S}, policy::Policy, updater::Updater, initial_belief)

    if !isnull(sim.initial_state)
        s = get(sim.initial_state)::S
    else
        s = rand(sim.rng, initial_belief)
    end
    eps = get(sim.eps, 0.0)
    max_steps = get(sim.max_steps, typemax(Int))

    disc = 1.0
    r_total = 0.0

    b = initialize_belief(updater, initial_belief)

    step = 1

    while disc > eps && !isterminal(pomdp, s) && step <= max_steps # TODO also check for terminal observation
        a = action(policy, b)

        sp, o, r = generate_sor(pomdp, s, a, sim.rng)

        r_total += disc*r

        s = sp

        bp = update(updater, b, a, o)
        b = bp

        disc *= discount(pomdp)
        step += 1
    end

    return r_total
end

@POMDP_require simulate(sim::RolloutSimulator, mdp::MDP, policy::Policy) begin
    if isnull(sim.initial_state)
        @req initial_state(::typeof(mdp), ::typeof(sim.rng))
    end
    istate = initial_state(mdp, sim.rng)
    @subreq simulate(sim, mdp, policy, istate)
end

@POMDP_require simulate(sim::RolloutSimulator, mdp::MDP, policy::Policy, initial_state) begin
    P = typeof(mdp)
    S = typeof(initial_state)
    A = action_type(mdp)
    @req isterminal(::P, ::S)
    @req action(::typeof(policy), ::S)
    @req generate_sr(::P, ::S, ::A, ::typeof(sim.rng))
    @req discount(::P)
end

function simulate(sim::RolloutSimulator, mdp::MDP, policy::Policy)
    istate=get(sim.initial_state, initial_state(mdp, sim.rng))
    simulate(sim, mdp, policy, istate)
end

function simulate{S}(sim::RolloutSimulator, mdp::Union{MDP{S}, POMDP{S}}, policy::Policy, initial_state::S)

    eps = get(sim.eps, 0.0)
    max_steps = get(sim.max_steps, typemax(Int))

    s = initial_state

    disc = 1.0
    r_total = 0.0
    step = 1

    while disc > eps && !isterminal(mdp, s) && step <= max_steps
        a = action(policy, s)

        sp, r = generate_sr(mdp, s, a, sim.rng)

        r_total += disc*r

        s = sp

        disc *= discount(mdp)
        step += 1
    end

    return r_total
end
