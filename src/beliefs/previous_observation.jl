# a belief that just stores the previous observation
# maintained by @zsunberg

# policies based on the previous observation only are often pretty good
# e.g. for the crying baby problem
"""
Updater that stores the most recent observation as the belief.

The belief is Nullable and is null if there is no observation available.
"""
struct PreviousObservationUpdater{O} <: Updater end

initialize_belief{O}(u::PreviousObservationUpdater{O}, d::Any, b=nothing) = Nullable{O}()
initialize_belief{O}(u::PreviousObservationUpdater{O}, o::O, b=nothing) = Nullable{O}(o)

update{O}(bu::PreviousObservationUpdater{O}, old_b, action, obs::O, b=nothing) = Nullable{O}(obs)

"""
Updater that stores the most recent observation as the belief.
"""
struct FastPreviousObservationUpdater{O} <: Updater end

# the only way this belief can be initialized is with a correct observation
initialize_belief{O}(u::FastPreviousObservationUpdater{O}, o::O) = o
update{O}(bu::FastPreviousObservationUpdater{O}, old_b, action, obs::O) = obs

"""
Updater that stores the most recent observation as the belief.

On the first step (when initialize_belief is called), it uses the default.
"""
struct PrimedPreviousObservationUpdater{O} <: Updater
    default::O
end
initialize_belief(u::PrimedPreviousObservationUpdater, b) = u.default
update{O}(u::PrimedPreviousObservationUpdater{O}, old_b, action, obs::O) = obs
