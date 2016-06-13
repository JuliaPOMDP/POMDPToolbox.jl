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
    max_steps::Nullable{Integer}
end
RolloutSimulator(rng::AbstractRNG) = RolloutSimulator(rng, Nullable{Any}(), Nullable{Float64}(), Nullable{Int}())
RolloutSimulator() = RolloutSimulator(MersenneTwister(rand(UInt32)))
function RolloutSimulator(;rng=MersenneTwister(rand(UInt32)),
                           initial_state=Nullable{Any}(),
                           eps=Nullable{Float64}(),
                           max_steps=Nullable{Integer}())
    return RolloutSimulator(rng, initial_state, eps, max_steps)
end

function simulate(sim::RolloutSimulator, pomdp::POMDP, policy::Policy, updater::Updater, initial_belief)

    if !isnull(sim.initial_state)
        s = deepcopy(get(sim.initial_state))
    else
        s = rand(sim.rng, initial_belief, create_state(pomdp))
    end
    eps = get(sim.eps, 0.0)
    max_steps = get(sim.max_steps, typemax(Int))

    disc = 1.0
    r_total = 0.0

    b = initialize_belief(updater, initial_belief) #XXX change this to convert
    # I think this deepcopy is necessary because the memory will be reused
    if b === initial_belief
        b = deepcopy(initial_belief)
    end
    a = create_action(pomdp)
    sp = create_state(pomdp)
    o = create_observation(pomdp)

    bp = create_belief(updater)
    step = 1

    while disc > eps && !isterminal(pomdp, s) && step <= max_steps # TODO also check for terminal observation
        a = action(policy, b, a)

        sp, o, r = generate_sor(pomdp, s, a, sim.rng, sp, o)

        r_total += disc*r

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

    return r_total
end

function simulate{S,A}(sim::RolloutSimulator, mdp::MDP{S,A}, policy::Policy, initial_state::S=sim.initial_state)

    eps = get(sim.eps, 0.0)
    max_steps = get(sim.max_steps, typemax(Int))

    disc = 1.0
    r_total = 0.0

    # I think this deepcopy is necessary because the memory will be reused
    s = deepcopy(initial_state)
    a = create_action(mdp)
    sp = create_state(mdp)

    step = 1

    while disc > eps && !isterminal(mdp, s) && step <= max_steps
        a = action(policy, s, a)

        sp, r = generate_sr(mdp, s, a, sim.rng, sp)

        r_total += disc*r

        # alternates using the memory allocated for s and sp so nothing new has to be allocated
        tmp = s
        s = sp
        sp = tmp

        disc *= discount(mdp)
        step += 1
    end

    return r_total
end
