# some implementations for convenience
# maintained by Zach Sunberg

actions(mdp::MDP{S,Bool}) where S = (true, false)
actions(mdp::MDP{S,Bool}, s::S, t::Tuple{Bool,Bool}=(true,false)) where S = (true,false)
actions(mdp::POMDP{S,Bool,O}) where {S,O} = (true, false)
actions(mdp::POMDP{S,Bool,O}, s::S, t::Tuple{Bool,Bool}=(true,false)) where {S,O} = (true,false)
n_actions(mdp::MDP{S,Bool}) where S = 2
n_actions(mdp::POMDP{S,Bool,O}) where {S, O} = 2

actions(mdp::MDP{S,Int}, s::S, r::AbstractRange) where S = actions(mdp)

rand(rng::AbstractRNG, t::Tuple{Bool, Bool}) = rand(rng, Bool)
rand(t::Tuple{Bool, Bool}) = rand(Bool)

iterator(s::AbstractVector) = s
iterator(s::Tuple) = s
iterator(r::AbstractRange) = r
iterator(g::Base.Generator) = g

states(mdp::MDP{Bool}) = (true, false)
states(mdp::POMDP{Bool}) = (true, false)
n_states(mdp::MDP{Bool}) = 2
n_states(mdp::POMDP{Bool}) = 2

observations(::POMDP{S,A,Bool}) where {S,A} = (true,false)
observations(::POMDP{S,A,Bool}, s::S) where {S,A} = (true,false)
n_observations(::POMDP{S,A,Bool}) where {S,A} = 2

state_index(mdp::Union{MDP, POMDP}, s::Int) = s
action_index(mdp::Union{MDP, POMDP}, a::Int) = a
obs_index(mdp::Union{MDP, POMDP}, o::Int) = o

state_index(mdp::Union{MDP, POMDP}, s::Bool) = s+1
action_index(mdp::Union{MDP, POMDP}, a::Bool) = a+1
obs_index(mdp::Union{MDP, POMDP}, o::Bool) = o+1
