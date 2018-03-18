
struct KMarkovUpdater <: Updater
    k::Int64
end

function initialize_belief{O}(bu::KMarkovUpdater, obs::O, b=nothing)
    obs_stacked = Vector{O}(bu.k)
    for i=1:bu.k
        obs_stacked[i] = obs
    end
    return obs_stacked
end

function update{O}(bu::KMarkovUpdater, old_b::Vector{O}, action, obs::O, b=nothing)
    obs_stacked = Vector{O}(bu.k)
    for i=1:bu.k-1
        obs_stacked[i] = old_b[i+1]
    end
    obs_stacked[bu.k] = obs
    return obs_stacked
end
