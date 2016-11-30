function uniform_state_distribution(pomdp::POMDP)
    d = DiscreteBelief(n_states(pomdp))
    return d
end
