__precompile__()


module POMDPToolbox

using GenerativeModels
using POMDPs

import POMDPs: Updater, update, initialize_belief, pdf, updater
import POMDPs: Simulator, simulate
import POMDPs: action, solve
import POMDPs: actions, action_index, state_index, obs_index, iterator, states, n_actions, n_states
import Base: rand, rand!

# export commons
export
    update,
    initialize_belief,
    create_belief,
    pdf,
    updater,
    simulate,
    action,
    solve,
    create_policy


# only include the things that are working
# export things immediately above the file they are contained in

# beliefs
export
    VoidUpdater   
include("beliefs/void.jl")

export 
    DiscreteBelief,
    DiscreteUpdater,
    product
include("beliefs/discrete.jl")

export
    PreviousObservationUpdater,
    FastPreviousObservationUpdater
include("beliefs/previous_observation.jl")

export
    Particle,
    ParticleBelief,
    ParticleDistribution,
    SIRParticleUpdater
include("beliefs/particle.jl")

# convenience
include("convenience/implementations.jl")

# policies
export
    RandomPolicy,
    RandomSolver
include("policies/random.jl")

export
    VectorPolicy,
    VectorSolver
include("policies/vector.jl")

export
    FunctionPolicy,
    FunctionSolver
include("policies/function.jl")

# simulators
export RolloutSimulator
include("simulators/rollout.jl")

export HistoryRecorder
include("simulators/history_recorder.jl")

# model tools
export uniform_state_distribution
include("model/initial.jl")

export
    ordered_states,
    ordered_actions,
    ordered_observations
include("model/ordered_spaces.jl")

# tools for random sampling
export
    WeightVec,
    sample
include("random/weight_vec.jl")

include("distributions/distributions_jl.jl")

# testing
export test_solver
include("testing/solver.jl")

export 
    probability_check,
    obs_prob_consistency_check,
    trans_prob_consistency_check
include("testing/model.jl")

end # module
