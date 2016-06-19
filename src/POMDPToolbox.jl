__precompile__()


module POMDPToolbox

using GenerativeModels
using Distributions
using POMDPs

import POMDPs: Updater, update, initialize_belief, create_belief, domain, pdf, updater
import POMDPs: Simulator, simulate
import POMDPs: action, solve, create_policy
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
    create_policy,
    rand


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

# policies
export
    RandomPolicy,
    RandomSolver
include("policies/random.jl")

# simulators
export RolloutSimulator
include("simulators/rollout.jl")

export HistoryRecorder
include("simulators/history_recorder.jl")

# model tools
export uniform_state_distribution
include("model/initial.jl")

# testing
export test_solver
include("testing/solver.jl")

export 
    probability_check,
    obs_prob_consistancy_check,
    trans_prob_consistancy_check
include("testing/model.jl")

end # module
