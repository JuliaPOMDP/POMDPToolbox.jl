let
    using POMDPModels

    mdp = GridWorld()
    policy = RandomPolicy(mdp)
    counts = Dict(a=>0 for a in iterator(actions(mdp)))

    wrapper = PolicyWrapper(policy, payload=counts) do policy, counts, s
        a = action(policy, s)
        counts[a] += 1
        return a
    end

    h = simulate(HistoryRecorder(max_steps=100), mdp, wrapper)
    for (a, count) in wrapper.payload
        println("policy chose action $a $count of $(n_steps(h)) times.")
    end
end
