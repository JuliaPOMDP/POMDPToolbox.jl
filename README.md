# POMDPToolbox
[![Build Status](https://travis-ci.org/JuliaPOMDP/POMDPToolbox.jl.svg?branch=master)](https://travis-ci.org/JuliaPOMDP/POMDPToolbox.jl)
[![Coverage Status](https://coveralls.io/repos/github/JuliaPOMDP/POMDPToolbox.jl/badge.svg?)](https://coveralls.io/github/JuliaPOMDP/POMDPToolbox.jl?)

Support tools for POMDPs.jl. This is a supported [JuliaPOMDP](https://github.com/JuliaPOMDP) package that provides tools
for belief updating, problem modeling, and running simulations.

The most important tools in this package are the [simulators](#simulators). They can be used to easily run simulations of POMDP problems and policies.

## Installation

This package requires [POMDPs.jl](https://github.com/JuliaPOMDP). To install this module run the following command:

```julia
using POMDPs
POMDPs.add("POMDPToolbox")
```

## Code structure

Within src, there are three directories representing classes of tools, beliefs, policies, and simulators.

Within each class directory, each file contains one tool. Each file should clearly indicate who is the maintainer of that file.

## Tools

### Beliefs
#### [`discrete.jl`](src/beliefs/discrete.jl)
Dense discrete probability distribution and updater.

Create an updater with `DiscreteUpdater(pomdp)`; create a belief with `DiscreteBelief(pomdp, b)`, where `b` is a vector of probabilities; create a uniform belief with `uniform_belief(pomdp)`.

States sampled from a `DiscreteBelief` will be actual states (of type `state_type(pomdp)`) instead of integer indices as in previous versions, and actual states instead of indices should be used in `pdf(b::DiscreteBelief, s)`. `DiscreteBelief` uses `state_index(pomdp, s)` to keep track of the states internally.

#### [`particle.jl`](src/beliefs/particle.jl)
Basic particle filter (deprecated; use [ParticleFilters.jl](https://github.com/JuliaPOMDP/ParticleFilters.jl))
#### [`previous_observation.jl`](src/beliefs/previous_observation.jl)
Beliefs (and updaters) that only deal with the most recent observation

- `PreviousObservationUpdater` maintains a "belief" that is a `Nullable{O}` where `O` is the observation type. The "belief" is null if there is no observation available, and contains the previous observation if there is one.
- `FastPreviousObservationUpdater` just returns the previous observation when `update` is called. There is no mechanism for representing the case when an observation is not available.
- `PrimedPreviousObservationUpdater` also returns the previous observation, but if an observation is not available, it returns a default.

#### [`k_previous_observation.jl`](src/beliefs/k_previous_observation.jl)
`KMarkovUpdater` maintains a "belief" that is a `Vector{O}` where `O` is the observation type. It consists of the last k observations where k is an integer to pass to the constructor of `KMarkovUpdater`. The last observation is at the end of the vector and the oldest one is at the beginning.
Example:
```julia
up = KMarkovUpdater(5)
s0 = initial_state(pomdp, rng)
initial_observation = generate_o(pomdp, s0, rng)
initial_obs_vec = fill(initial_observation, 5)
hr = HistoryRecorder(rng=rng, max_steps=100)
hist = simulate(hr, pomdp, policy, up, initial_obs_vec, s0)
```

#### [`void.jl`](src/beliefs/void.jl)
An updater useful for when a belief is not necessary (i.e. for a random policy). `update` always returns `nothing`.

### Convenience
#### [`implementations.jl`](src/convenience/implementations.jl)
Default implementations for simple cases (e.g. `states(::MDP{Bool, Bool})`).

### Distributions
#### [`distributions_jl.jl`](src/distributions/distributions_jl.jl)
Provides some compatibility with [Distributions.jl](https://github.com/JuliaStats/Distributions.jl).

#### [`sparse_cat.jl`](src/distributions/sparse_cat.jl)
Provides a sparse categorical distribution `SparseCat`. This distribution simply stores a vector of objects and a vector of their associated probabilities. It is optimized for value iteration with a fast implementation of `weighted_iterator`. Both `pdf` and `rand` are order n.

Example: `SparseCat([1,2,3], [0.1,0.2,0.7])` is a categorical distribution that assignes probability 0.1 to `1`, 0.2 to `2`, 0.7 to `3`, and 0 to all other values.

#### [`weighted_iteration.jl`](src/distributions/weighted_iteration.jl)
Function for iterating through pairs of values and their probabilities in a distribution.

#### [`bool.jl`](src/distributions/bool.jl)
Distribution over an outcome being true. Create with `BoolDistribution(p_true)`. Obviously, the probability of false is simply `1 - p_true`.

### Model
#### [`info.jl`](src/model/info.jl)
Contains a small interface for outputting extra information (usually a `Dict` or `nothing`) from simulations.
- `sp, o, r, info = generate_sori(pomdp, s, a, rng)` and `sp, r, info = generate_sri(mdp, s, a, rng)` can be implemented to output info from the model when it simulates a step.
- `a, ainfo = action_info(policy, x)` can be implemented to output info from the policy when it chooses an action.
- `policy, sinfo = solve_info(solver, problem)` can be implemented to output info from the solver when it solves a POMDP or MDP.
The action info and transition info can be accessed by simulating with `HistoryRecorder` and using `eachstep(hist, "i,ai")` or with `stepthrough(..., "i,ai")`.

#### [`generative_belief_mdp.jl`](src/model/generative_belief_mdp.jl)
Transforms a pomdp (and a belief updater) into a belief-space MDP.

Example (note that the states of the belief MDP are beliefs):
```julia
using POMDPModels
using POMDPToolbox

pomdp = BabyPOMDP()
updater = BabyBeliefUpdater(pomdp)

belief_mdp = GenerativeBeliefMDP(pomdp, updater)
@show state_type(belief_mdp) # POMDPModels.BoolDistribution

for (a, r, sp) in stepthrough(belief_mdp, RandomPolicy(belief_mdp), "a,r,sp", max_steps=10)
    @show a, r, sp
end
```

#### [`initial.jl`](src/model/initial.jl)
A uniform distribution for discrete problems.
#### [`ordered_spaces.jl`](src/model/ordered_spaces.jl)
Contains 3 functions, `ordered_states`, `ordered_actions`, and `ordered_observations` that return vectors of all the items in a space correctly ordered according to the respective index function. For example `ordered_actions(mdp)` will return a vector `v`, containing all of the actions in `actions(mdp)` in the order such that  `action_index(mdp, v[i]) == i`.

### Policies
#### [`alpha_vector.jl`](src/policies/alpha_vector.jl)
Represents a policy with a set of alpha vectors. Can be constructed with `AlphaVectorPolicy(pomdp, alphas, action_map)`, where `alphas` is either a vector of vectors or an |S| x |A| matrix. The `action_map` argument is a vector of actions with length equal to the number of alpha vectors. If this argument is not provided, `ordered_actions` is used to generate a default action map.
#### [`function.jl`](src/policies/function.jl)
Turns a function into a `Policy` object, i.e. when `action` is called on `FunctionPolicy(s->1)`, it will always return `1` as the action.
#### [`random.jl`](src/policies/random.jl)
A policy that returns a randomly selected action using `rand(rng, actions(pomdp))`.
#### [`stochastic.jl`](src/policies/stochastic.jl)
A more flexible set of randomized policies including the following:

- `StochasticPolicy` samples actions from an arbitrary distribution.
- `EpsGreedy` uses epsilon-greedy action selection.

#### [`vector.jl`](src/policies/vector.jl)
Tabular policies including the following:

- `VectorPolicy` holds a vector of actions, one for each state, ordered according to `state_index`.
- `ValuePolicy` holds a matrix of values for state-action pairs and chooses the action with the highest value at the given state

#### [`utility_wrapper.jl`](src/policies/utility_wrapper.jl)
A wrapper for policies to collect statistics and handle errors.

        PolicyWrapper

    Flexible utility wrapper for a policy designed for collecting statistics about planning.

    Carries a function, a policy, and optionally a payload (that can be any type).

    The function should typically be defined with the do syntax. Each time `action` is called on the wrapper, this function will be called.

    If there is no payload, it will be called with two argments: the policy and the state/belief. If there is a payload, it will be called with three arguments: the policy, the payload, and the current state or belief. The function should return an appropriate action. The idea is that, in this function, `action(policy, s)` should be called, statistics from the policy/planner should be collected and saved in the payload, exceptions can be handled, and the action should be returned.

    # Example

        using POMDPModels
        using POMDPToolbox

        mdp = GridWorld()
        policy = RandomPolicy(mdp)
        counts = Dict(a=>0 for a in iterator(actions(mdp)))

        # with a payload
        statswrapper = PolicyWrapper(policy, payload=counts) do policy, counts, s
            a = action(policy, s)
            counts[a] += 1
            return a
        end

        h = simulate(HistoryRecorder(max_steps=100), mdp, statswrapper)
        for (a, count) in payload(statswrapper)
            println("policy chose action \$a \$count of \$(n_steps(h)) times.")
        end

        # without a payload
        errwrapper = PolicyWrapper(policy) do policy, s
            try
                a = action(policy, s)
            catch ex
                warn("Caught error in policy; using default")
                a = :left
            end
            return a
        end

        h = simulate(HistoryRecorder(max_steps=100), mdp, errwrapper)

### Simulators
#### [`rollout.jl`](src/simulators/rollout.jl)

`RolloutSimulator` is the simplest MDP or POMDP simulator. When `simulate` is called, it simply simulates a single trajectory of the process and returns the discounted reward.

```julia
rs = RolloutSimulator()
mdp = GridWorld()
policy = RandomPolicy(mdp)

r = simulate(rs, mdp, policy)
```
See output of `?RolloutSimulator` for a list of keyword arguments.

#### [`history_recorder.jl`](src/simulators/history_recorder.jl)

`HistoryRecorder` runs a simulation and records the trajectory. It returns an `MDPHistory` or `POMDPHistory` (see `history.jl` below).

```julia
hr = HistoryRecorder(max_steps=100)
pomdp = TigerPOMDP()
policy = RandomPolicy(pomdp)

h = simulate(hr, pomdp, policy)
```
See the output of `?HistoryRecorder` for a list of keyword arguments.

#### [`history.jl`](src/simulators/history.jl)
Contains types for representing simulation histories (i.e. trajectories or episodes).

An `MDPHistory` represents a state-action-reward history from simulating an MDP. A `POMDPHistory` contains a record of the states, actions, observations, rewards, and beliefs encountered during a simulation of a POMDP. Both of these are subtypes of `SimHistory`.

The steps of any `SimHistory` object `h` can be iterated through as follows:

```julia
for (s, a, r, sp) in eachstep(h, "(s, a, r, sp)")    
    println("reward $r received when state $sp was reached after action $a was taken in state $s")
end
```

The possible valid elements in the iteration specification are
- `s` - the initial state in a step
- `b` - the initial belief in the step (for POMDPs only)
- `a` - the action taken in the step
- `r` - the reward received for the step
- `sp` - the final state at the end of the step (s')
- `o` - the observation received during the step (note that this is usually based on `sp` instead of `s`)
- `bp` - the belief after being updated based on `o` (for POMDPs only)
- `i` - info from the state transition (from `generate_sri` for MDPs or `generate_sori` for POMDPs)
- `ai` - info from the policy decision (from `action_info`)
- `ui` - info from the belief update (from `update_info`)

Examples:
```julia
collect(eachstep(h, "ao"))
```
will produce a vector of action-observation tuples.

```julia
collect(norm(sp-s) for (s,sp) in eachstep(h, "s,sp"))
```
will produce a vector of the distances traveled on each step (assuming the state is a Euclidean vector).

Notes:
- The iteration specification can be specified as a tuple of symbols (e.g. `(:s, :a)`) instead of a string.
- For type stability in performance-critical code, one should construct an iterator directly using `HistoryIterator{typeof(h), (:a,:r)}(h)` rather than `eachstep(h, "ar")`.

`state_hist(h)`, `action_hist(h)`, `observation_hist(h)` `belief_hist(h)`, and `reward_hist(h)` will return vectors of the states, actions, and rewards, and `undiscounted_reward(h)` and `discounted_reward(h)` will return the total rewards collected over the trajectory. `n_steps(h)` returns the number of steps in the history. `exception(h)` and `backtrace(h)` can be used to hold an exception if the simulation failed to finish.

`view(h, range)` (e.g. `view(h, 1:n_steps(h)-4)`) can be used to create a view of the history object `h` that only contains a certain range of steps. The object returned by `view` is a `SimHistory` that can be iterated through and manipulated just like a complete `SimHistory`.


#### [`sim.jl`](src/simulators/sim.jl)
The `sim` function provides a convenient way to interact with a POMDP or MDP environment. The first argument is a function that is called at every time step and takes a state (in the case of an MDP) or an observation (in the case of a POMDP) as the argument and then returns an action. The second argument is a pomdp or mdp. It is intended to be used with Julia's `do` syntax as follows:

```julia
pomdp = TigerPOMDP()
history = sim(pomdp, max_steps=10) do obs
    println("Observation was $obs.")
    return TIGER_OPEN_LEFT
end
```
This allows a flexible and general way to interact with a POMDP environment without creating new `Policy` types.

Note: by default, since there is no observation before the first action, on the first call to the `do` block, `obs` is `nothing`.

#### [`stepthrough.jl`](src/simulators/stepthrough.jl)
The `stepthrough` function exposes a simulation as an iterator so that the steps can be iterated through with a for loop syntax as follows:

```julia
pomdp = BabyPOMDP()
policy = RandomPolicy(pomdp)

for (s, a, o, r) in stepthrough(pomdp, policy, "s,a,o,r", max_steps=10)
    println("in state $s")
    println("took action $o")
    println("received observation $o and reward $r")
end
```
For more information, see the documentation for the `stepthrough` function.

The `StepSimulator` contained in this file can provide the same functionality with the following syntax:
```julia
sim = StepSimulator("s,a,r,sp")
for (s,a,r,sp) in simulate(sim, problem, policy)
    # do something
end
```

#### [`parallel.jl`](src/simulators/parallel.jl)
The `run_parallel` function can be used to conveniently run simulations in parallel. Example:

```julia
using POMDPToolbox
using POMDPModels

pomdp = BabyPOMDP()
fwc = FeedWhenCrying()
rnd = solve(RandomSolver(MersenneTwister(7)), pomdp)

q = [] # vector of the simulations to be run
push!(q, Sim(pomdp, fwc, max_steps=32, rng=MersenneTwister(4), metadata=Dict(:policy=>"feed when crying")))
push!(q, Sim(pomdp, rnd, max_steps=32, rng=MersenneTwister(4), metadata=Dict(:policy=>"random")))

# this creates two simulations, one with the feed-when-crying policy and one with a random policy

data = run_parallel(q)

# by default, the dataframe output contains the reward and the contents of `metadata`
@show data
# data = 2×2 DataFrames.DataFrame
# │ Row │ policy             │ reward   │
# ├─────┼────────────────────┼──────────┤
# │ 1   │ "feed when crying" │ -4.5874  │
# │ 2   │ "random"           │ -27.4139 │

# to perform additional analysis on each of the simulations one can define a processing function with the `do` syntax:
data2 = run_parallel(q, progress=false) do sim, hist
    println("finished a simulation - final state was $(last(state_hist(hist)))")
    return [:steps=>n_steps(hist), :reward=>discounted_reward(hist)]
end

@show data2
# 2×3 DataFrames.DataFrame
# │ Row │ policy             │ reward   │ steps │
# ├─────┼────────────────────┼──────────┼───────┤
# │ 1   │ "feed when crying" │ -18.2874 │ 32.0  │
# │ 2   │ "random"           │ -17.7054 │ 32.0  │

```

### Testing
#### [`model.jl`](src/testing/model.jl)
Generic functions for testing POMDP models.
#### [`solver.jl`](src/testing/solver.jl)
Standard functions for testing solvers. New solvers should be able to be used with the functions in this file.
