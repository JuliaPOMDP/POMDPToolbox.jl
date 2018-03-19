"""
Updater that stores the k most recent observations as the belief.
"""
struct KMarkovUpdater <: Updater
    k::Int
end

function initialize_belief{O}(bu::KMarkovUpdater, obs::O)
    b0 = CircularBuffer{O}(bu.k)
    for i=1:bu.k
        push!(b0, obs)
    end
    @assert isfull(b0)
    return b0
end

function update{O}(bu::KMarkovUpdater, old_b::CircularBuffer{O}, action, obs::O)
    new_b = CircularBuffer{O}(bu.k)
    append!(new_b, old_b)
    push!(new_b, obs)
    @assert isfull(new_b)
    @assert capacity(new_b) == bu.k
    return new_b
end
