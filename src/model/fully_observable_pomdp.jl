# Provides a structure for turning a mdp into a pomdp where observations are the states of the original mdp

struct FullyObservablePOMDP{S, A} <: POMDP{S,A,S}
    mdp::MDP{S, A}
end

# observations are the state of the MDP
# The observation distribution is modeled by a SparseCat distribution with only one element
POMDPs.observations(pomdp::FullyObservablePOMDP) = states(pomdp.mdp)
POMDPs.n_observations(pomdp::FullyObservablePOMDP) = n_states(pomdp.mdp)
POMDPs.obs_index{S, A}(pomdp::FullyObservablePOMDP{S, A}, o::S) = state_index(pomdp.mdp, o)

POMDPs.convert_o(T::Type{V}, o, pomdp::FullyObservablePOMDP) where {V<:AbstractArray} = convert_s(T, s, pomdp.mdp)
POMDPs.convert_o(T::Type{S}, vec::V, pomdp::FullyObservablePOMDP) where {S,V<:AbstractArray} = convert_s(T, vec, pomdp.mdp)


function POMDPs.generate_o(pomdp::FullyObservablePOMDP, s, a, rng::AbstractRNG)
    return s
end

function POMDPs.observation(pomdp::FullyObservablePOMDP, s, a)
    return SparseCat((s,), (1.,))
end

function POMDPs.observation(pomdp::FullyObservablePOMDP, s, a, sp)
    return SparseCat((sp,), (1.,))
end

POMDPs.isterminal_obs{S,A}(problem::FullyObservablePOMDP{S,A}, o::S) = isterminal(pomdp.mdp, o)

# inherit other function from the MDP type

POMDPs.states(pomdp::FullyObservablePOMDP) = states(pomdp.mdp)
POMDPs.actions(pomdp::FullyObservablePOMDP) = actions(pomdp.mdp)
POMDPs.transition{S,A}(pomdp::FullyObservablePOMDP{S,A}, s::S, a::A) = transition(pomdp.mdp, s, a)
POMDPs.initial_state_distribution(pomdp::FullyObservablePOMDP) = initial_state_distribution(pomdp.mdp)
POMDPs.initial_state(pomdp::FullyObservablePOMDP, rng::AbstractRNG) = initial_state(pomdp.mdp, rng)
POMDPs.generate_s(pomdp::FullyObservablePOMDP, s, a, rng::AbstractRNG) = generate_s(pomdp.mdp, s, a, rng)
POMDPs.generate_sr(pomdp::FullyObservablePOMDP, s, a, rng::AbstractRNG) = generate_sr(pomdp.mdp, s, a, rng)
POMDPs.reward{S,A}(pomdp::FullyObservablePOMDP{S, A}, s::S, a::A) = reward(pomdp.mdp, s, a)
POMDPs.isterminal(pomdp::FullyObservablePOMDP, s) = isterminal(pomdp.mdp, s)
POMDPs.discount(pomdp::FullyObservablePOMDP) = discount(pomdp.mdp)
POMDPs.n_states(pomdp::FullyObservablePOMDP) = n_states(pomdp.mdp)
POMDPs.n_actions(pomdp::FullyObservablePOMDP) = n_actions(pomdp.mdp)
POMDPs.state_index{S,A}(pomdp::FullyObservablePOMDP{S,A}, s::S) = state_index(pomdp.mdp, s)
POMDPs.action_index{S, A}(pomdp::FullyObservablePOMDP{S, A}, a::A) = action_index(pomdp.mdp, a)
POMDPs.convert_s(T::Type{V}, s, pomdp::FullyObservablePOMDP) where V<:AbstractArray = convert_s(T, s, pomdp.mdp)
POMDPs.convert_s(T::Type{S}, vec::V, pomdp::FullyObservablePOMDP) where {S,V<:AbstractArray} = convert_s(T, vec, pomdp.mdp)
POMDPs.convert_a(T::Type{V}, a, pomdp::FullyObservablePOMDP) where V<:AbstractArray = convert_a(T, a, pomdp.mdp)
POMDPs.convert_a(T::Type{A}, vec::V, pomdp::FullyObservablePOMDP) where {A,V<:AbstractArray} = convert_a(T, vec, pomdp.mdp)
