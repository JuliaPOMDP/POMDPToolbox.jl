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

function solve(s::VectorSolver, mdp::MDP, p::VectorPolicy=create_policy(s,mdp))
    p.mdp = mdp
    p.act = s.act
    return p
end


"""
A generic MDP policy that consists of a value table. The entry at `state_index(mdp, s)` is the action that will be taken in state `s`.
"""
mutable struct ValuePolicy{A, P <: Union{MDP, POMDP}} <: Policy
    mdp::P
    value_table::Matrix{Float64}
    act::Vector{A}
end
function ValuePolicy(mdp::P) where {P <: Union{MDP, POMDP}}
    A = action_type(mdp)
    return ValuePolicy{A, P}(mdp, zeros(n_states(mdp), n_actions(mdp)), ordered_actions(mdp))
end

action(p::ValuePolicy, s) = p.act[indmax(p.value_table[state_index(p.mdp, s),:])]

@POMDP_require ValuePolicy(mdp::Union{MDP, POMDP}) begin
    M = typeof(mdp)
    @req n_states(::M)
    @req n_actions(::M)
    @subreq ordered_actions(mdp)
end

@POMDP_require action(p::ValuePolicy, s) begin
    @req state_index(::typeof(p.mdp), ::typeof(s))
end
