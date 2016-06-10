
"""
   probability_check(pomdp::POMDP) 

Checks if the transition and observation function of the discrete `pomdp` 
have probability mass that sums up to unity for all state-action pairs.
"""
function probability_check(pomdp::POMDP)
    obs_prob_consistancy_check(pomdp)
    trans_prob_consistancy_check(pomdp)
end

"""
    obs_prob_consistancy_check(pomdp::POMDP)

Checks if the observation function of the discrete `pomdp` 
has probability mass that sums up to unity for all state-action pairs.
"""
function obs_prob_consistancy_check(pomdp::POMDP)
    # initalize space
    sspace = states(pomdp)
    aspace = actions(pomdp)
    # iterate through all s-a pairs
    for s in iterator(sspace)
        for a in iterator(aspace)
            obs = observation(pomdp, s, a)
            p = 0.0
            for sp in iterator(sspace)
                p += pdf(obs, sp)
            end
            @assert isapprox(p, 1.0) "Observation probability does not sum to unity for state: ", s, " action: ", a
        end
    end
end

"""
    trans_prob_consistancy_check(pomdp::Union{MDP, POMDP})

Checks if the transition function of the discrete problem 
has probability mass that sums up to unity for all state-action pairs.
"""
function trans_prob_consistancy_check(pomdp::Union{MDP, POMDP})
    # initalize space
    sspace = states(pomdp)
    aspace = actions(pomdp)
    # iterate through all s-a pairs
    for s in iterator(sspace)
        for a in iterator(aspace)
            tran = transition(pomdp, s, a)
            p = 0.0
            for sp in iterator(sspace)
                p += pdf(tran, sp)
            end
            @assert isapprox(p, 1.0) "Transition probability does not sum to unity for state: ", s, " action: ", a
        end
    end
end

