module POMDPToolbox

using POMDPs

import POMDPs: Updater, update, convert, create_belief, domain, pdf, updater
import POMDPs: Simulator, simulate
import POMDPs: action, solve, create_policy
import Base: rand, rand!

using GenerativeModels

# old exports... this will get removed
#=
export 
    # Support for updating beliefs
    DiscreteUpdater,
    DiscreteBelief,
    create_belief,
    length,
    index,
    weight,
    sum,
    fill!,
    setindex!,
    getindex,
    copy!,
    vec,
    valid,
    update,
    # beliefs
    PreviousObservation,
    PreviousObservationUpdater,
    EmptyBelief,
    EmptyUpdater,
    # simulators
    RolloutSimulator,
    HistoryRecorder,
    simulate,
    # policies
    RandomPolicy,
    RandomSolver
    =#

# only include the things that are working
# export things immediately above the file they are contained in

# beliefs
export
    EmptyBelief,
    EmptyUpdater   
include("beliefs/empty.jl")
export 
    DiscreteBelief,
    DiscreteUpdater
include("beliefs/beliefs.jl")

export
    PreviousObservation,
    PreviousObservationUpdater
include("beliefs/previous_observation.jl")

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

end # module
