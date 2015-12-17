### RandomPolicy ###
# a generic policy that uses the actions function to create a list of actions
# and then randomly samples an action from it.
type RandomPolicy <: Policy
    rng::AbstractRNG
    problem::POMDP
    action_space # stores the action space so that it does not have to be reallocated each time
end
# The constructor below should be used to create the policy so that the action space is initialized correctly
RandomPolicy(problem::POMDP; rng=MersenneTwister()) = RandomPolicy(rng, problem, actions(problem))

## policy execution ##
# b can be a belief or state, should work the same (assuming that POMDPs.jl #45 is accepted)
function action(policy::RandomPolicy, b, action::Action)
    actions(policy.problem, b, policy.action_space)
    return rand!(policy.rng, action, policy.action_space)
end
action(policy::RandomPolicy, b) = action(policy, b, create_action(policy.problem))

### Random Solver ###
# solver that produces a random policy
type RandomSolver <: Solver
    rng::AbstractRNG
end
RandomSolver(;rng=MersenneTwister()) = RandomSolver(rng)
solve(solver::RandomSolver, problem::POMDP, policy::RandomPolicy=create_policy(solver, problem)) = policy
create_policy(solver::RandomSolver, problem::POMDP) = RandomPolicy(problem, rng=solver.rng)
