using POMDPToolbox
using POMDPModels
using Base.Test

############################################################
################# TESTS PARTICLE FILTER ####################
############################################################

pomdp = TigerPOMDP()
s = false
n = 10000 # num particles
bu = SIRParticleUpdater(pomdp, n)

b = initialize_belief(bu, initial_state_distribution(pomdp))

a = 0
o = false

srand(1)
bp = update(bu, b, a, o)
w1 = pdf(bp, s)
srand(1)
bp = update(bu, b, a, o)
bp.keep_dict = false
w2 = pdf(bp, s)

bp.keep_dict = false
os = [true, false, true, false, true, false, true, false, true, false]
b = initialize_belief(bu, initial_state_distribution(pomdp))
for o in os
    b = update(bu, b, a, o)
end
w3 = pdf(b, s)
s

s = rand(MersenneTwister(0), b, s) 

# dict and array method should give same pdf
@test isapprox(w1, w2, atol=0.01)
# after one update should have ~0.85 prob
@test isapprox(w1, 0.85, atol=0.01)
# after 10 of each observations should be back to uniform belief
@test isapprox(w3, 0.5, atol=0.05)
