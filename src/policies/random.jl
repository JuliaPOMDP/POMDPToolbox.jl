### RandomPolicy ###
# maintained by @zsunberg
"""
a generic policy that uses the actions function to create a list of actions and then randomly samples an action from it.
"""
type RandomPolicy <: Policy
    rng::AbstractRNG
    problem::Union{POMDP,MDP}
    updater::Updater # set this to use a custom updater, by default it will be a void updater
    action_space # stores the action space so that it does not have to be reallocated each time
end
# The constructor below should be used to create the policy so that the action space is initialized correctly
RandomPolicy(problem::Union{POMDP,MDP};
             rng=MersenneTwister(),
             updater=VoidUpdater()) = RandomPolicy(rng, problem, updater, actions(problem))

## policy execution ##
function action(policy::RandomPolicy, s, action)
    policy.action_space = actions(policy.problem, s, policy.action_space)
    return rand(policy.rng, policy.action_space, action)
end

function action(policy::RandomPolicy, b::Void, action)
    return rand(policy.rng, policy.action_space, action)
end

function action(policy::RandomPolicy, s)
    policy.action_space = actions(policy.problem, s, policy.action_space)
    return rand(policy.rng, policy.action_space)
end

function action(policy::RandomPolicy, b::Void)
    return rand(policy.rng, policy.action_space)
end


## convenience functions ##
updater(policy::RandomPolicy) = policy.updater


"""
solver that produces a random policy
"""
type RandomSolver <: Solver
    rng::AbstractRNG
end
RandomSolver(;rng=MersenneTwister(rand(UInt32))) = RandomSolver(rng)
solve(solver::RandomSolver, problem::Union{POMDP,MDP}, policy::RandomPolicy=create_policy(solver, problem)) = policy
create_policy(solver::RandomSolver, problem::Union{POMDP,MDP}) = RandomPolicy(problem, rng=solver.rng)
