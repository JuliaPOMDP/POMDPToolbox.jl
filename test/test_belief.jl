using POMDPs
using POMDPToolbox
using POMDPModels

pomdp = TigerPOMDP()
bu = DiscreteUpdater(pomdp)
bold = convert(bu, initial_state_distribution(pomdp), create_belief(bu))

a = 0
o = true
bnew = update(bu, bold, a, o)

