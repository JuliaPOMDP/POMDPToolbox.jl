### RandomPolicy ###
# maintained by @zsunberg
"""
a generic policy that uses the actions function to create a list of actions and then randomly samples an action from it.
"""
mutable struct RandomPolicy{RNG<:AbstractRNG, P<:Union{POMDP,MDP}, U<:Updater} <: Policy
    rng::RNG
    problem::P
    updater::U # set this to use a custom updater, by default it will be a void updater
end
# The constructor below should be used to create the policy so that the action space is initialized correctly
RandomPolicy(problem::Union{POMDP,MDP};
             rng=Base.GLOBAL_RNG,
             updater=VoidUpdater()) = RandomPolicy(rng, problem, updater)

## policy execution ##
function action(policy::RandomPolicy, s)
    return rand(policy.rng, actions(policy.problem, s))
end

function action(policy::RandomPolicy, b::Void)
    return rand(policy.rng, actions(policy.problem))
end

## convenience functions ##
updater(policy::RandomPolicy) = policy.updater


"""
solver that produces a random policy
"""
mutable struct RandomSolver <: Solver
    rng::AbstractRNG
end
RandomSolver(;rng=Base.GLOBAL_RNG) = RandomSolver(rng)
solve(solver::RandomSolver, problem::Union{POMDP,MDP}) = RandomPolicy(solver.rng, problem, VoidUpdater())
