# RolloutSimulator
# maintained by @zsunberg

"""
A fast simulator that just returns the reward

The simulation will be terminated when either
1) a terminal state is reached (as determined by `isterminal()` or
2) the discount factor is as small as `eps` or
3) max_steps have been executed
"""
type RolloutSimulator <: Simulator
    rng::AbstractRNG

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
    return RolloutSimulator(rng, initial_state, eps, max_steps)
end

function simulate(sim::RolloutSimulator, pomdp::POMDP, policy::Policy, bu::Updater=updater(policy))
    dist = initial_state_distribution(pomdp)
    return simulate(sim, pomdp, policy, bu, dist)
end


function simulate(sim::RolloutSimulator, pomdp::POMDP, policy::Policy, updater::Updater, initial_belief)

    if !isnull(sim.initial_state)
        s = deepcopy(get(sim.initial_state))
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


function simulate{S,A}(sim::RolloutSimulator, mdp::MDP{S,A}, policy::Policy, initial_state::S=sim.initial_state)

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
