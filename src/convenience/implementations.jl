# some implementations for convenience
# maintained by Zach Sunberg

actions{S}(mdp::MDP{S,Bool}) = (true, false)
actions{S}(mdp::MDP{S,Bool}, s::S, t::Tuple{Bool,Bool}=(true,false)) = (true,false)
actions{S,O}(mdp::POMDP{S,Bool,O}) = (true, false)
actions{S,O}(mdp::POMDP{S,Bool,O}, s::S, t::Tuple{Bool,Bool}=(true,false)) = (true,false)
n_actions{S}(mdp::MDP{S,Bool}) = 2
n_actions{S,O}(mdp::POMDP{S,Bool,O}) = 2

actions{S}(mdp::MDP{S,Int}, s::S, r::Range) = actions(mdp)

rand(rng::AbstractRNG, t::Tuple{Bool, Bool}, b::Bool=false) = rand(rng, Bool)

iterator(s::AbstractVector) = s
iterator(s::Tuple) = s
iterator(r::Range) = r

states(mdp::MDP{Bool}) = (true, false)
states(mdp::POMDP{Bool}) = (true, false)
n_states(mdp::MDP{Bool}) = 2
n_states(mdp::POMDP{Bool}) = 2

state_index(mdp::Union{MDP, POMDP}, s::Int) = s
action_index(mdp::Union{MDP, POMDP}, a::Int) = a
obs_index(mdp::Union{MDP, POMDP}, o::Int) = o
