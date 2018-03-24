# RolloutSimulator
# maintained by @zsunberg

"""
A fast simulator that just returns the reward

The simulation will be terminated when either
1) a terminal state is reached (as determined by `isterminal()` or
2) the discount factor is as small as `eps` or
3) max_steps have been executed

Keyword Arguments:
    - eps
    - max_steps

Usage (optional arguments in brackets):
    ro = RolloutSimulator()
    history = simulate(ro, pomdp, policy, [updater [, init_belief [, init_state]]])
"""
struct RolloutSimulator{RNG<:AbstractRNG} <: Simulator
    rng::RNG

    # optional: if these are null, they will be ignored
    max_steps::Nullable{Int}
    eps::Nullable{Float64}

    # DEPRECATED: remove in v0.2.8 or higher
    initial_state::Nullable{Any}
end

# These are the only safe constructors to use
RolloutSimulator(rng::AbstractRNG, d::Int=typemax(Int)) = RolloutSimulator(rng, Nullable{Int}(d), Nullable{Float64}(), Nullable{Any}())
function RolloutSimulator(;rng=MersenneTwister(rand(UInt32)),
                           initial_state=Nullable{Any}(),
                           eps=Nullable{Float64}(),
                           max_steps=Nullable{Int}())
    if !isnull(initial_state)
        warn("The initial_state argument for RolloutSimulator is deprecated. The initial state should be specified as the last argument to simulate(...).")
    end
    return RolloutSimulator{typeof(rng)}(rng, max_steps, eps, initial_state)
end

# COMPATIBILITY CONSTRUCTOR: DO NOT USE!
# Once version 0.2.7 is registered, start having this throw a warning in master
function RolloutSimulator(rng::AbstractRNG, is::Nullable{Any}, eps::Nullable{Float64}, ms::Nullable{Int})
    return RolloutSimulator(rng, ms, eps, is)
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
    @req rand(::typeof(sim.rng), ::typeof(initial_belief))
    @subreq simulate(sim, pomdp, policy, updater, initial_belief, s)
end

function simulate{S}(sim::RolloutSimulator, pomdp::POMDP{S}, policy::Policy, updater::Updater, initial_belief)

    if !isnull(sim.initial_state)
        s = convert(S, get(sim.initial_state))::S
    else
        s = rand(sim.rng, initial_belief)::S
    end

    return simulate(sim, pomdp, policy, updater, initial_belief, s)
end

@POMDP_require simulate(sim::RolloutSimulator, pomdp::POMDP, policy::Policy, updater::Updater, initial_belief, s) begin
    P = typeof(pomdp)
    S = state_type(P)
    A = action_type(P)
    O = obs_type(P)
    @req initialize_belief(::typeof(updater), ::typeof(initial_belief))
    @req isterminal(::P, ::S)
    @req discount(::P)
    @req generate_sor(::P, ::S, ::A, ::typeof(sim.rng))
    b = initialize_belief(updater, initial_belief)
    @req action(::typeof(policy), ::typeof(b))
    @req update(::typeof(updater), ::typeof(b), ::A, ::O)
end

function simulate(sim::RolloutSimulator, pomdp::POMDP, policy::Policy, updater::Updater, initial_belief, s)

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
