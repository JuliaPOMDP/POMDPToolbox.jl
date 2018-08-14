# maintained by @zsunberg
# an empty belief
# for use with e.g. a random policy
mutable struct VoidUpdater <: Updater end

initialize_belief(::VoidUpdater, ::Any) = nothing
initialize_belief(::VoidUpdater, ::Any, ::Any) = nothing
create_belief(::VoidUpdater) = nothing

update(::VoidUpdater, ::B, ::Any, ::Any, b=nothing) where B = nothing
