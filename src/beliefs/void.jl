# maintained by @zsunberg
# an empty belief
# for use with e.g. a random policy
type VoidUpdater <: Updater{Void} end

initialize_belief(::VoidUpdater, ::Any) = nothing
initialize_belief(::VoidUpdater, ::Any, ::Any) = nothing
create_belief(::VoidUpdater) = nothing

update{B}(::VoidUpdater, ::B, ::Any, ::Any, b=nothing) = nothing
