module POMDPToolbox

using POMDPs

import POMDPs: Belief, update_belief!
import Base: rand, rand!

export 
    # Support for interpolants
    Interpolants,
    rand,
    interpolants!,
    interpolants_gaussian_1d!,
    interpolants_uniform_1d!,
    # Support for updating beliefs
    DiscreteBelief,
    length,
    index,
    weight,
    fill!,
    vec,
    valid,
    update_belief!,
    # beliefs
    PreviousObservation,
    EmptyBelief


include("interpolants.jl")
include("beliefs.jl")
include("beliefs_momdp.jl")

end # module
