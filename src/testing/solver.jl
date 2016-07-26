# A test for solvers
# Maintained by @zsunberg

type TestSimulator
    rng::AbstractRNG
    max_steps::Int
end

function simulate{S,A,O,B}(sim::TestSimulator, pomdp::POMDP{S,A,O}, policy::Policy, updater::Updater{B}, initial_distribution::AbstractDistribution)

    s = rand(sim.rng, initial_distribution)
    b = initialize_belief(updater, initial_distribution)

    disc = 1.0
    r_total = 0.0

    step = 1

    while !isterminal(pomdp, s) && step <= sim.max_steps # TODO also check for terminal observation
        a = action(policy, b)

        trans_dist = transition(pomdp, s, a)
        sp = rand(sim.rng, trans_dist)

        r_total += disc*reward(pomdp, s, a, sp)

        obs_dist = observation(pomdp, s, a, sp)
        o = rand(sim.rng, obs_dist)

        b = update(updater, b, a, o)

        disc *= discount(pomdp)
        s = sp
        step += 1
    end

    return r_total
end

"""
    test_solver(solver::Solver, problem::POMDP)

Use the solver to solve the specified problem, then run a simulation.

This is designed to illustrate how solvers are expected to function. All solvers should be able to complete this standard test with the simple models in the POMDPModels package.

To run this with a solver called YourSolver, run
```
using POMDPToolbox
using POMDPModels

solver = YourSolver(# initialize with parameters #)
test_solver(solver, BabyPOMDP())

```
"""
function test_solver(solver::Solver, problem::POMDP; max_steps=10)
    
    policy = solve(solver, problem)
    up = updater(policy)

    sim = TestSimulator(MersenneTwister(1), max_steps)

    simulate(sim, problem, policy, up, initial_state_distribution(problem))
end
