# SimHistory
# maintained by @zsunberg

abstract SimHistory

"""
An object that contains a MDP simulation history

Returned by simulate when called with a HistoryRecorder. Iterate through the (s, a, r, s') tuples in MDPSimHistory h like this:

    for (s, a, r, sp) in h
        # do something
    end
"""
immutable MDPHistory{S,A} <: SimHistory
    state_hist::Vector{S}
    action_hist::Vector{A}
    reward_hist::Vector{Float64}

    # if capture_exception is true and there is an exception, it will be stored here
    exception::Nullable{Exception}
    backtrace::Nullable{Any}
end

"""
An object that contains a POMDP simulation history

Returned by simulate when called with a HistoryRecorder. Iterate through the (s, b, a, r, s', o') tuples in POMDPSimHistory h like this:

    for (s, b, a, r, sp, op) in h
        # do something
    end
"""
immutable POMDPHistory{S,A,O,B} <: SimHistory
    state_hist::Vector{S}
    action_hist::Vector{A}
    observation_hist::Vector{O}
    belief_hist::Vector{B}
    reward_hist::Vector{Float64}

    # if capture_exception is true and there is an exception, it will be stored here
    exception::Nullable{Exception}
    backtrace::Nullable{Any}
end

# accessors: use these to access the members - in case the implementation changes
n_steps(h::SimHistory) = length(h.state_hist)-1

state_hist(h::SimHistory) = h.state_hist
action_hist(h::SimHistory) = h.action_hist
observation_hist(h::SimHistory) = h.observation_hist
belief_hist(h::SimHistory) = h.belief_hist
reward_hist(h::SimHistory) = h.reward_hist

exception(h::SimHistory) = h.exception
Base.backtrace(h::SimHistory) = h.backtrace

undiscounted_reward(h::SimHistory) = sum(h.reward_hist)
function discounted_reward(h::SimHistory, problem::Union{MDP,POMDP})
    disc = 1.0
    r_total = 0.0
    for i in 1:length(h.reward_hist)
        r_total += disc*h.reward_hist[i]
        disc *= discount(problem)
    end
end

# iteration
# you can iterate through the history and get a (s,a,r,s') or (s,b,a,r,s',o')
Base.length(h::SimHistory) = n_steps(h)
Base.start(h::SimHistory) = 1
Base.done(h::SimHistory, i::Int) = i > n_steps(h)
function Base.next(h::MDPHistory, i::Int)
    return ((h.state_hist[i],
             h.action_hist[i],
             h.reward_hist[i],
             h.state_hist[i+1]
            ), i+1
           )
end
function Base.next(h::POMDPHistory, i::Int)
    return ((h.state_hist[i],
             h.belief_hist[i],
             h.action_hist[i],
             h.reward_hist[i],
             h.state_hist[i+1],
             h.observation_hist[i]
            ), i+1
           )
end
