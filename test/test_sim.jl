mdp = GridWorld()

sim(mdp, max_steps=100) do state
    @assert isa(state, GridWorldState)    
    acts = actions(mdp)
    return rand(acts)
end

pomdp = BabyPOMDP()

sim(pomdp, max_steps=100) do obs
    @assert isa(obs, Bool)
    acts = actions(pomdp)
    return rand(acts)
end
