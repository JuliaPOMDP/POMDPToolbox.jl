### Vector Policy ###
# maintained by @zsunberg

"""
A generic MDP policy that consists of a vector of actions. The entry at `state_index(mdp, s)` is the action that will be taken in state `s`.
"""
type VectorPolicy{S,A} <: Policy{S}
    mdp::MDP{S,A}
    act::Vector{A}
end

action(p::VectorPolicy, s) = p.act[state_index(p.mdp, s)]

"""
Solver for VectorPolicy. Doesn't do any computation - just sets the action vector.
"""
type VectorSolver{A}
    act::Vector{A}
end

create_policy{S,A}(s::VectorSolver{A}, mdp::MDP{S,A}) = VectorPolicy(mdp, Array(A,0))

function solve{S,A}(s::VectorSolver{A}, mdp::MDP{S,A}, p::VectorPolicy=create_policy(s,mdp))
    p.mdp = mdp
    p.act = s.act
    return p
end
