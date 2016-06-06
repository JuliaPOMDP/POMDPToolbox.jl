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

srand(1)
bp = update(bu, b, a, o)
w1 = pdf(bp, s)
bu.keep_dict = false
srand(1)
bp = update(bu, b, a, o)
w2 = pdf(bp, s)

# dict and array method should give same pdf
@test_approx_eq w1 w2
# after one updater should have ~0.85 prob
@test_approx_eq_eps w1 0.85 0.01

