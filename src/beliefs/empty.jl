# maintained by @zsunberg
# an empty belief
# for use with e.g. a random policy
type EmptyBelief <: Belief end

type EmptyUpdater <: BeliefUpdater end

convert_belief(::EmptyUpdater, ::BeliefUpdater) = EmptyBelief()
create_belief(::EmptyUpdater) = EmptyBelief()

function update(::EmptyUpdater, ::Belief, ::Any, ::Any, b::Belief=EmptyBelief())
    return b
end
