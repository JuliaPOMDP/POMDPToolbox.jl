# provide a structure to extract the underlying MDP of a POMDP

struct UnderlyingMDP{P, S, A} <: MDP{S, A} where P <: POMDP{S, A, Any}
    pomdp::P
end

function UnderlyingMDP{S, A, O}(pomdp::POMDP{S, A, O})
    P = typeof(pomdp)
    return UnderlyingMDP{P, S, A}(pomdp)
end

POMDPs.transition{P, S, A}(mdp::UnderlyingMDP{P, S, A}, s::S, a::A) = transition(mdp.pomdp, s, a)

POMDPs.initial_state_distribution(mdp::UnderlyingMDP) = initial_state_distribution(mdp.pomdp)

POMDPs.generate_s{P, S, A}(mdp::UnderlyingMDP{P, S, A}, s::S, a::A, rng::AbstractRNG) = generate_s(mdp.pomdp, s, a, rng)

POMDPs.generate_sr{P, S, A}(mdp::UnderlyingMDP{P, S, A}, s::S, a::A, rng::AbstractRNG) = generate_sr(mdp.pomdp, s, a, rng)

POMDPs.initial_state(mdp::UnderlyingMDP, rng::AbstractRNG) = initial_state(mdp.pomdp, rng)

POMDPs.states(mdp::UnderlyingMDP) = states(mdp.pomdp)
POMDPs.actions(mdp::UnderlyingMDP) = actions(mdp.pomdp)

POMDPs.reward{P, S, A}(mdp::UnderlyingMDP{P, S, A}, s::S, a::A) = reward(mdp.pomdp, s, a)
POMDPs.reward{P, S, A}(mdp::UnderlyingMDP{P, S, A}, s::S, a::A, sp::S) = reward(mdp.pomdp, s, a, sp)
POMDPs.isterminal{P, S, A}(mdp ::UnderlyingMDP{P, S, A}, s::S) = isterminal(mdp.pomdp, s)
POMDPs.discount(mdp::UnderlyingMDP) = discount(mdp.pomdp)

POMDPs.n_actions(mdp::UnderlyingMDP) = n_actions(mdp.pomdp)
POMDPs.n_states(mdp::UnderlyingMDP) = n_states(mdp.pomdp)
POMDPs.state_index{P, S, A}(mdp::UnderlyingMDP{P, S, A}, s::S) = state_index(mdp.pomdp, s)
POMDPs.action_index{P, S, A}(mdp::UnderlyingMDP{P, S, A}, a::A) = action_index(mdp.pomdp, a)
