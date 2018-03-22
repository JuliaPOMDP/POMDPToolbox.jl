"""
Updater that stores the k most recent observations as the belief.
"""
struct KMarkovUpdater <: Updater
    k::Int
end

function initialize_belief(bu::KMarkovUpdater, obs_vec::AbstractVector)
    if length(obs_vec) != bu.k
        error("KMarkovUpdater: The length of the initial observation vector
               does not match the number of observation to stack\n"*throw_example(bu))
    end
    return obs_vec
end

function update{O}(bu::KMarkovUpdater, old_b::AbstractVector{O}, action, obs)
    obs_stacked = Vector{O}(bu.k)
    if !isa(obs, O)
        error("KMarkovUpdater: Observation did not match previous observation type.\n"*throw_example(bu))
    end
    for i=1:bu.k-1
        obs_stacked[i] = old_b[i+1]
    end
    obs_stacked[bu.k] = obs
    return obs_stacked
end

function initialize_belief(bu::KMarkovUpdater, obs_vec)
    error("KMarkovUpdater: To initialize the belief, pass in a vector of observation.\n"*throw_example(bu))
end

function throw_example(bu::KMarkovUpdater)
    example = """
    Did you forget to pass the initial observation to the simulator?
    Example:
    ```julia
    up = KMarkovUpdater(5)
    s0 = initial_state(pomdp, rng)
    initial_observation = generate_o(pomdp, s0, rng)
    initial_obs_vec = fill(initial_observation, 5)
    hr = HistoryRecorder(rng=rng, max_steps=100)
    hist = simulate(hr, pomdp, policy, up, initial_obs_vec, s0)
    ```
    """
    return example
end
