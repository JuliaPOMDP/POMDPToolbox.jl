# FunctionPolicy
# A policy represented by a function
# maintained by @zsunberg

"""
FunctionPolicy

Policy `p=FunctionPolicy(f)` returns `f(x)` when `action(p, x)` is called.
"""
type FunctionPolicy <: Policy
    f::Function
end

"""
FunctionSolver

Solver for a FunctionPolicy.
"""
type FunctionSolver <: Solver
    f::Function
end

solve(s::FunctionSolver, mdp::Union{MDP,POMDP}) = FunctionPolicy(s.f)

action(p::FunctionPolicy, x) = p.f(x)
