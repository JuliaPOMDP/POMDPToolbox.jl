module POMDPToolbox

using POMDPs

import POMDPs: Belief, BeliefUpdater, update, convert_belief, create_belief, domain, pdf, updater
import POMDPs: Simulator, simulate
import POMDPs: action, solve, create_policy
import Base: rand, rand!

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
export RolloutSimulator
include("simulators/rollout.jl")

export
    EmptyBelief,
    EmptyUpdater   
include("beliefs/empty.jl")

end # module
