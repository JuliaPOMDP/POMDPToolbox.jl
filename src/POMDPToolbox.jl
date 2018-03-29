__precompile__()


module POMDPToolbox

using POMDPs

import POMDPs: Updater, update, initialize_belief, pdf, mode, updater
import POMDPs: Simulator, simulate
import POMDPs: action, value, solve
import POMDPs: actions, action_index, state_index, obs_index, iterator, sampletype, states, n_actions, n_states, observations, n_observations, discount, isterminal
import POMDPs: generate_sr, initial_state
import Base: rand, rand!, mean, ==
import DataStructures: CircularBuffer, isfull, capacity, push!, append!

using ProgressMeter
using StatsBase
using DataFrames


# export commons
export
    update,
    initialize_belief,
    create_belief,
    pdf,
    updater,
    simulate,
    action,
    solve


# only include the things that are working
# export things immediately above the file they are contained in

# model tools
export
    generate_sri,
    generate_sori,
    action_info,
    solve_info,
    update_info
include("model/info.jl")

export uniform_state_distribution
include("model/initial.jl")

export
    ordered_states,
    ordered_actions,
    ordered_observations
include("model/ordered_spaces.jl")

export GenerativeBeliefMDP
include("model/generative_belief_mdp.jl")


# beliefs
include("beliefs/BeliefUpdaters.jl")
import .BeliefUpdaters

export
    VoidUpdater

@deprecate VoidUpdater BeliefUpdaters.VoidUpdater

export
    DiscreteBelief,
    DiscreteUpdater,
    uniform_belief,
    product

@deprecate DiscreteBelief BeliefUpdaters.DiscreteBelief
@deprecate DiscreteBelief(pomdp, b; check=true) BeliefUpdaters.DiscreteBelief(pomdp, b; check=check)
@deprecate DiscreteUpdater BeliefUpdaters.DiscreteUpdater
@deprecate uniform_belief BeliefUpdaters.uniform_belief
@deprecate product BeliefUpdaters.product

export
    PreviousObservationUpdater,
    FastPreviousObservationUpdater,
    PrimedPreviousObservationUpdater
@deprecate PreviousObservationUpdater BeliefUpdaters.PreviousObservationUpdater
@deprecate FastPreviousObservationUpdater BeliefUpdaters.FastPreviousObservationUpdater
@deprecate PrimedPreviousObservationUpdater BeliefUpdaters.PrimedPreviousObservationUpdater

export
    KMarkovUpdater

include("beliefs/k_previous_observations.jl")

export
    Particle,
    ParticleBelief,
    ParticleDistribution,
    SIRParticleUpdater,
    mode
include("beliefs/particle.jl")

# convenience
include("convenience/implementations.jl")

# policies
include("policies/Policies.jl")
import .Policies

export
    AlphaVectorPolicy

@deprecate AlphaVectorPolicy Policies.AlphaVectorPolicy

export
    VectorPolicy,
    VectorSolver,
    ValuePolicy

@deprecate VectorPolicy Policies.VectorPolicy
@deprecate VectorSolver Policies.VectorSolver
@deprecate ValuePolicy Policies.ValuePolicy

export
    RandomPolicy,
    RandomSolver

@deprecate RandomPolicy Policies.RandomPolicy
@deprecate RandomPolicy(problem; rng=Base.GLOBAL_RNG, updater=VoidUpdater()) Policies.RandomPolicy(problem; rng=rng, updater=updater)
@deprecate RandomSolver Policies.RandomSolver
@deprecate RandomSolver(;rng=Base.GLOBAL_RNG) Policies.RandomSolver(;rng=rng)

export
    StochasticPolicy,
    UniformRandomPolicy,
    CategoricalTabularPolicy,
    EpsGreedyPolicy

@deprecate StochasticPolicy Policies.StochasticPolicy
@deprecate UniformRandomPolicy Policies.UniformRandomPolicy
@deprecate CategoricalTabularPolicy Policies.CategoricalTabularPolicy
@deprecate EpsGreedyPolicy Policies.EpsGreedyPolicy

export
    FunctionPolicy,
    FunctionSolver

@deprecate FunctionPolicy Policies.FunctionPolicy
@deprecate FunctionSolver Policies.FunctionSolver

export
    PolicyWrapper,
    payload

@deprecate PolicyWrapper Policies.PolicyWrapper
@deprecate PolicyWrapper(f, p; payload=Nullable()) Policies.PolicyWrapper(f, p; payload=payload)
@deprecate payload Policies.payload

# simulators
export RolloutSimulator
include("simulators/rollout.jl")

export
    SimHistory,
    POMDPHistory,
    MDPHistory,
    AbstractPOMDPHistory,
    AbstractMDPHistory,
    HistoryIterator,
    eachstep,
    state_hist,
    action_hist,
    observation_hist,
    belief_hist,
    reward_hist,
    info_hist,
    ainfo_hist,
    uinfo_hist,
    exception,
    backtrace,
    undiscounted_reward,
    discounted_reward,
    n_steps,
    step_tuple
include("simulators/history.jl")

export sim
include("simulators/sim.jl")

export HistoryRecorder
include("simulators/history_recorder.jl")

export
    StepSimulator,
    stepthrough
include("simulators/stepthrough.jl")

export
    Sim,
    run,
    run_parallel,
    problem
include("simulators/parallel.jl")


# tools for distributions
include("distributions/distributions_jl.jl")

export
    weighted_iterator
include("distributions/weighted_iteration.jl")

export
    SparseCat
include("distributions/sparse_cat.jl")

export
    BoolDistribution
include("distributions/bool.jl")

# testing
export test_solver
include("testing/solver.jl")

export
    probability_check,
    obs_prob_consistency_check,
    trans_prob_consistency_check
include("testing/model.jl")

end # module
