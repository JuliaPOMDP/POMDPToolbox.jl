module POMDPToolbox

using POMDPs

import POMDPs: Belief, belief
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
    sum,
    fill!,
    setindex!,
    getindex,
    copy!,
    vec,
    valid,
    update_belief!,
    belief,
    # beliefs
    PreviousObservation,
    EmptyBelief


include("interpolants.jl")
include("beliefs.jl")
include("beliefs_momdp.jl")

end # module
