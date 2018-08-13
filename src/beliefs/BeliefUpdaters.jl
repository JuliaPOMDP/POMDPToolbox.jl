module BeliefUpdaters

using POMDPs
import POMDPs: Updater, update, initialize_belief, pdf, mode, updater, iterator
import Base: ==
import Random: rand, rand!
import Statistics: mean
using POMDPToolbox: ordered_states
using StatsBase
using Random

export
    VoidUpdater
include("void.jl")

export
    DiscreteBelief,
    DiscreteUpdater,
    uniform_belief,
    product                     # Remove because deprecated
include("discrete.jl")


export
    PreviousObservationUpdater,
    FastPreviousObservationUpdater,
    PrimedPreviousObservationUpdater

include("previous_observation.jl")

end
