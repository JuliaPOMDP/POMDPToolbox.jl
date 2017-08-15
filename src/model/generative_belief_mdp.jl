# Provides a structure for turning a pomdp and an updater into a generative belief MDP
# maintained by @zsunberg

struct GenerativeBeliefMDP{P<:POMDP, U<:Updater, B, A} <: MDP{B, A}
    pomdp::P
    updater::U
end

function GenerativeBeliefMDP(pomdp::P, up::U) where {P<:POMDP, U<:Updater}
    # XXX hack to determine belief type
    b0 = initialize_belief(up, initial_state_distribution(pomdp))
    GenerativeBeliefMDP{P, U, typeof(b0), action_type(pomdp)}(pomdp, up)
end

function generate_sr(bmdp::GenerativeBeliefMDP, b, a, rng::AbstractRNG)
    s = rand(rng, b)
    sp, o, r = generate_sor(bmdp.pomdp, s, a, rng) # maybe this should have been generate_or?
    bp = update(bmdp.updater, b, a, o)
    return bp, r
end

function initial_state(bmdp::GenerativeBeliefMDP, rng::AbstractRNG)
    return initialize_belief(bmdp.updater, initial_state_distribution(bmdp.pomdp))
end

actions(bmdp::GenerativeBeliefMDP{P,U,B,A}, b::B) where {P,U,B,A} = actions(bmdp.pomdp, b)
actions(bmdp::GenerativeBeliefMDP) = actions(bmdp.pomdp)
