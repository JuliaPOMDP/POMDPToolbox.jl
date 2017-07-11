# SimHistory
# maintained by @zsunberg

abstract SimHistory
abstract AbstractMDPHistory{S,A} <: SimHistory
abstract AbstractPOMDPHistory{S,A,O,B} <: SimHistory

"""
An object that contains a MDP simulation history

Returned by simulate when called with a HistoryRecorder. Iterate through the (s, a, r, s') tuples in MDPHistory h like this:

    for (s, a, r, sp) in eachstep(h)
        # do something
    end
"""
struct MDPHistory{S,A} <: AbstractMDPHistory{S,A}
    state_hist::Vector{S}
    action_hist::Vector{A}
    reward_hist::Vector{Float64}

    discount::Float64

    # if capture_exception is true and there is an exception, it will be stored here
    exception::Nullable{Exception}
    backtrace::Nullable{Any}
end

"""
An object that contains a POMDP simulation history

Returned by simulate when called with a HistoryRecorder. Iterate through the (s, b, a, r, s', o) tuples in POMDPHistory h like this:

    for (s, b, a, r, sp, o) in eachstep(h, "s,b,a,r,sp,o")
        # do something
    end
"""
struct POMDPHistory{S,A,O,B} <: AbstractPOMDPHistory{S,A,O,B}
    state_hist::Vector{S}
    action_hist::Vector{A}
    observation_hist::Vector{O}
    belief_hist::Vector{B}
    reward_hist::Vector{Float64}

    discount::Float64

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
discount(h::SimHistory) = h.discount

undiscounted_reward(h::SimHistory) = sum(reward_hist(h))
function discounted_reward(h::SimHistory)
    disc = 1.0
    r_total = 0.0
    for i in 1:length(reward_hist(h))
        r_total += disc*reward_hist(h)[i]
        disc *= discount(h)
    end
    return r_total
end

# iteration
# you can iterate through the history and get a (s,a,r,s') or (s,b,a,r,s',o')
Base.length(h::SimHistory) = n_steps(h)
Base.start(h::SimHistory) = 1
Base.done(h::SimHistory, i::Int) = i > n_steps(h)
Base.next(h::SimHistory, i::Int) = (step_tuple(h, i), i+1)

function step_tuple(h::MDPHistory, i::Int)
    return (state_hist(h)[i],
            action_hist(h)[i],
            reward_hist(h)[i],
            state_hist(h)[i+1]
           )
end
function step_tuple(h::POMDPHistory, i::Int)
    return (state_hist(h)[i],
            belief_hist(h)[i],
            action_hist(h)[i],
            reward_hist(h)[i],
            state_hist(h)[i+1],
            observation_hist(h)[i]
           )
end



typealias Inds Union{Range,Colon,Real}

Base.view(h::AbstractMDPHistory, inds::Inds) = SubMDPHistory(h, inds)
Base.view(h::AbstractPOMDPHistory, inds::Inds) = SubPOMDPHistory(h, inds)

struct SubMDPHistory{S,A,H<:AbstractMDPHistory,I<:Inds} <: AbstractMDPHistory{S,A}
    parent::H
    inds::I
end
SubMDPHistory{S,A,I<:Inds}(h::AbstractMDPHistory{S,A}, inds::I) = SubMDPHistory{S,A,typeof(h),I}(h, inds)

struct SubPOMDPHistory{S,A,O,B,H<:AbstractPOMDPHistory,I<:Inds} <: AbstractPOMDPHistory{S,A,O,B}
    parent::H
    inds::I
end
SubPOMDPHistory{S,A,O,B,I<:Inds}(h::AbstractPOMDPHistory{S,A,O,B}, inds::I) = SubPOMDPHistory{S,A,O,B,typeof(h),I}(h, inds)

typealias SubHistory Union{SubMDPHistory, SubPOMDPHistory}

n_steps(h::SubHistory) = length(h.inds)

state_hist(h::SubHistory) = state_hist(h.parent)[minimum(h.inds):maximum(h.inds)+1]
action_hist(h::SubHistory) = action_hist(h.parent)[h.inds]
observation_hist(h::SubHistory) = observation_hist(h.parent)[h.inds]
belief_hist(h::SubHistory) = belief_hist(h.parent)[h.inds]
reward_hist(h::SubHistory) = reward_hist(h.parent)[h.inds]

step_tuple(h::SubHistory, i::Int) = step_tuple(h.parent, h.inds[i])

exception(h::SubHistory) = exception(h.parent)
Base.backtrace(h::SubHistory) = backtrace(h.parent)
discount(h::SubHistory) = discount(h.parent)


# iterators
struct HistoryIterator{H<:SimHistory, SPEC}
    history::H
end

# Note this particular function is not type-stable
function HistoryIterator(history::SimHistory, spec::String)
    # XXX should throw warnings for unrecognized specification characters
    syms = [Symbol(m.match) for m in eachmatch(r"(sp|bp|s|a|r|b|o)", spec)]
    if length(syms) == 1
        return HistoryIterator{typeof(history), first(syms)}(history)
    else
        return HistoryIterator{typeof(history), tuple(syms...)}(history)
    end
end

function HistoryIterator(history::SimHistory, spec::Tuple)
    @assert all(isa(s, Symbol) for s in spec)
    return HistoryIterator{typeof(history), spec}(history)
end
HistoryIterator(h::SimHistory, spec::Symbol) = HistoryIterator{typeof(h), spec}(h)

eachstep(hist::SimHistory, spec) = HistoryIterator(hist, spec)
eachstep(mh::AbstractMDPHistory) = eachstep(mh, (:s, :a, :r, :sp))
eachstep(mh::AbstractPOMDPHistory) = eachstep(mh, (:a, :o))

function sym_to_call(sym::Symbol)
    if sym == :s
        return :(state_hist(it.history)[i])
    elseif sym == :a
        return :(action_hist(it.history)[i])
    elseif sym == :r
        return :(reward_hist(it.history)[i])
    elseif sym == :sp
        return :(state_hist(it.history)[i+1])
    elseif sym == :b
        return :(belief_hist(it.history)[i])
    elseif sym == :o
        return :(observation_hist(it.history)[i])
    elseif sym == :bp
        return :(belief_hist(it.history)[i+1])
    end
end

@generated function step_tuple(it::HistoryIterator, i::Int)
    spec = it.parameters[2]
    if isa(spec, Tuple)
        calls = []
        for sym in spec
            push!(calls, sym_to_call(sym))
        end

        return quote
            return tuple($(calls...))
        end
    else
        @assert isa(spec, Symbol)
        return quote
            return $(sym_to_call(spec))
        end
    end
end

Base.length(it::HistoryIterator) = n_steps(it.history)
Base.start(it::HistoryIterator) = 1
Base.done(it::HistoryIterator, i::Int) = i > length(it)
Base.next(it::HistoryIterator, i::Int) = (step_tuple(it, i), i+1)

Base.getindex(it::HistoryIterator, i) = step_tuple(it, i)
