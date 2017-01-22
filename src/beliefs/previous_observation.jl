# a belief that just stores the previous observation
# maintained by @zsunberg

# policies based on the previous observation only are often pretty good
# e.g. for the crying baby problem
"""
Updater that stores the most recent observation as the belief.

The belief is Nullable and is null if there is no observation available.
"""
type PreviousObservationUpdater{O} <: Updater{Nullable{O}} end

initialize_belief{O}(u::PreviousObservationUpdater{O}, d::Any, b=nothing) = Nullable{O}()
initialize_belief{O}(u::PreviousObservationUpdater{O}, o::O, b=nothing) = Nullable{O}(o)

update{O}(bu::PreviousObservationUpdater{O}, old_b, action, obs::O, b=nothing) = Nullable{O}(obs)

"""
Updater that stores the most recent observation as the belief.
"""
type FastPreviousObservationUpdater{O} <: Updater{O} end

# the only way this belief can be initialized is with a correct observation
initialize_belief(u::FastPreviousObservationUpdater, o) = o
update{O}(bu::FastPreviousObservationUpdater{O}, old_b, action, obs::O) = obs
