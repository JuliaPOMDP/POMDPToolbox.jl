### Vector Policy ###
# maintained by @zsunberg and @etotheipluspi

"""
A generic MDP policy that consists of a vector of actions. The entry at `state_index(mdp, s)` is the action that will be taken in state `s`.
"""
mutable struct VectorPolicy{S,A} <: Policy
    mdp::MDP{S,A}
    act::Vector{A}
end

action(p::VectorPolicy, s) = p.act[state_index(p.mdp, s)]
action(p::VectorPolicy, s, a) = action(p, s)

"""
Solver for VectorPolicy. Doesn't do any computation - just sets the action vector.
"""
mutable struct VectorSolver{A}
    act::Vector{A}
end

create_policy(s::VectorSolver{A}, mdp::MDP{S,A}) where {S,A} = VectorPolicy(mdp, Array{A}(0))

function solve(s::VectorSolver{A}, mdp::MDP{S,A}, p::VectorPolicy=create_policy(s,mdp)) where {S,A}
    p.mdp = mdp
    p.act = s.act
    return p
end


"""
A generic MDP policy that consists of a value table. The entry at `state_index(mdp, s)` is the action that will be taken in state `s`.
"""
mutable struct ValuePolicy{A} <: Policy
    mdp::Union{MDP,POMDP}
    value_table::Matrix{Float64}
    act::Vector{A}
end
function ValuePolicy(mdp::Union{MDP,POMDP})
    acts = Any[]
    for a in iterator(actions(mdp))
        push!(acts, a)
    end
    return ValuePolicy(mdp, zeros(n_states(mdp), n_actions(mdp)), acts)
end

action(p::ValuePolicy, s) = p.act[indmax(p.value_table[state_index(p.mdp, s),:])]
