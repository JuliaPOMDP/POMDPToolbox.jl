# a belief that just stores the previous observation
# maintained by @zsunberg

# policies based on the previous observation only are often pretty good
# e.g. for the crying baby problem
# when there is not an observation available, the observation field may be null, so policies should check for this
type PreviousObservation{O}
    observation::Nullable{O}
    PreviousObservation() = new(Nullable{O}())
    PreviousObservation(obs) = new(Nullable{O}(obs))
end
PreviousObservation{O}(obs::O) = PreviousObservation{O}(Nullable{O}(obs))

type PreviousObservationUpdater{O} <: Updater{PreviousObservation} end

convert_belief{O,B}(u::PreviousObservationUpdater{O}, b::B) = PreviousObservation{O}()
create_belief{O}(u::PreviousObservationUpdater{O}) = PreviousObservation{O}()
rand(rng::AbstractRNG, b::PreviousObservation, thing=nothing) = nothing

function update{O}(bu::PreviousObservationUpdater, ::PreviousObservation{O}, action, obs::O, b::PreviousObservation=PreviousObservation(obs))
    if O.mutable
        b.observation = Nullable{O}(deepcopy(obs)) #XXX deepcopy is slow - need to replace this
    else
        b.observation = Nullable{O}(obs)
    end
    return b
end
