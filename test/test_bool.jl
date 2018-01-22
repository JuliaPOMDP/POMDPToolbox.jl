using POMDPToolbox
using Base.Test

# Hack to get this to build with POMDPModels
# this can be removed once BoolDistribution is removed from POMDPModels
BoolDistribution = POMDPToolbox.BoolDistribution

# testing constructor and pdf
d = BoolDistribution(0.3)
@test pdf(d, true) == 0.3
@test pdf(d, false) == 0.7

# testing iterator
@test iterator(d) == [true, false]

# testing ==
d2 = BoolDistribution(0.3)
@test d == d2

# testing hash
@test hash(d) == hash(d.p)
