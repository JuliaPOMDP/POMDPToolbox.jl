# maintained by @zsunberg
# an empty belief
# for use with e.g. a random policy
type EmptyBelief end

type EmptyUpdater <: Updater{EmptyBelief} end

convert_belief(::EmptyUpdater, ::Updater) = EmptyBelief()
create_belief(::EmptyUpdater) = EmptyBelief()
rand(rng::AbstractRNG, b::EmptyBelief, thing=nothing) = nothing

function update{B}(::EmptyUpdater, ::B, ::Any, ::Any, b::B=EmptyBelief())
    return b
end
