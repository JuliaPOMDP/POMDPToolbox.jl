using POMDPToolbox
using POMDPModels
using Base.Test

pomdp = TigerPOMDP()

probability_check(pomdp)

ordered_states(pomdp)
ordered_observations(pomdp)
ordered_actions(pomdp)
