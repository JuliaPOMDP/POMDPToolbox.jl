module POMDPToolbox

using POMDPs

import POMDPs: Belief, BeliefUpdater, update, convert_belief, create_belief
import POMDPs: Simulator, simulate
import Base: rand, rand!

export 
    # Support for interpolants
    Interpolants,
    rand,
    interpolants!,
    interpolants_gaussian_1d!,
    interpolants_uniform_1d!,
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
    #simulators
    RolloutSimulator,
    HistoryRecorder,
    simulate

include("interpolants.jl")
include("beliefs.jl")
include("beliefs_momdp.jl")
include("simulators.jl")

end # module
