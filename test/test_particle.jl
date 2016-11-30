using POMDPToolbox
using POMDPModels
using Base.Test

############################################################
################# TESTS PARTICLE FILTER ####################
############################################################

pomdp = TigerPOMDP()
s = create_state(pomdp)
n = 10000 # num particles
bu = SIRParticleUpdater(pomdp, n)

b = initialize_belief(bu, initial_state_distribution(pomdp))

a = create_action(pomdp)
o = create_observation(pomdp)
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

s = rand(MersenneTwister(), b, s) 

# dict and array method should give same pdf
@test_approx_eq_eps w1 w2 0.01
# after one updater should have ~0.85 prob
@test_approx_eq_eps w1 0.85 0.01
# after 10 of each observations should be back to uniform belief
@test_approx_eq_eps w3 0.5 0.05
