__precompile__()


module POMDPToolbox

using POMDPs

import POMDPs: Updater, update, initialize_belief, pdf, mode, updater
import POMDPs: Simulator, simulate
import POMDPs: action, value, solve
import POMDPs: actions, action_index, state_index, obs_index, iterator, sampletype, states, n_actions, n_states, observations, n_observations, discount, isterminal
import POMDPs: generate_sr, initial_state
import POMDPs: implemented
import Base: rand, rand!, mean, ==

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

# beliefs
export
    VoidUpdater
include("beliefs/void.jl")

export
    DiscreteBelief,
    DiscreteUpdater,
    uniform_belief,
    product
include("beliefs/discrete.jl")


export
    PreviousObservationUpdater,
    FastPreviousObservationUpdater,
    PrimedPreviousObservationUpdater
include("beliefs/previous_observation.jl")

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
export
    AlphaVectorPolicy,
    belief_vector,
    unnormalized_util
include("policies/alpha_vector.jl")

export
    VectorPolicy,
    VectorSolver,
    ValuePolicy
include("policies/vector.jl")

export
    RandomPolicy,
    RandomSolver
include("policies/random.jl")

export
    StochasticPolicy,
    UniformRandomPolicy,
    CategoricalTabularPolicy,
    EpsGreedyPolicy
include("policies/stochastic.jl")

export
    FunctionPolicy,
    FunctionSolver
include("policies/function.jl")

export
    PolicyWrapper,
    payload
include("policies/utility_wrapper.jl")

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

export FullyObservablePOMDP
include("model/fully_observable_pomdp.jl")

export UnderlyingMDP
include("model/underlying_mdp.jl")

# tools for distributions
include("distributions/distributions_jl.jl")

export obs_weight
include("model/obs_weight.jl")

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
