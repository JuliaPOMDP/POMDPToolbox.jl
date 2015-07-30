module POMDPToolbox

using POMDPs

import POMDPs: Belief, update_belief, update_belief!

export 
    # Support for interpolants
    Interpolants,
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
    update_belief,
    update_belief!


include("interpolants.jl")
include("beliefs.jl")
include("beliefs_momdp.jl")

end # module
