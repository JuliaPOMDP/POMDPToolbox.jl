module POMDPToolbox

using POMDPs

import POMDPs: Belief, BeliefUpdater, update, convert_belief, create_belief, domain, pdf
import POMDPs: Simulator, simulate
import POMDPs: action, solve, create_policy
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
    # simulators
    RolloutSimulator,
    HistoryRecorder,
    simulate,
    # policies
    RandomPolicy,
    RandomSolver


include("interpolants.jl")
include("beliefs.jl")
include("beliefs_momdp.jl")
include("simulators.jl")
include("policies.jl")

end # module
