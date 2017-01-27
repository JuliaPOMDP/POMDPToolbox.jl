using POMDPToolbox
using POMDPModels
using Base.Test

pomdp = TigerPOMDP()

probability_check(pomdp)

@test ordered_states(pomdp) == [false, true]
@test ordered_observations(pomdp) == [false, true]
@test ordered_actions(pomdp) == [0,1,2]
