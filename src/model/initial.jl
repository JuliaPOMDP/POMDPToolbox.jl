using Distributions

function uniform_state_distribution(pomdp::POMDP)
    d = Categorical(n_states(pomdp))
    return d
end
